package com.brightbuy.backend.catalogue;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import java.math.BigDecimal;
import java.sql.*;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class CatalogueRepositoryTests {
    DataSource source;
    Connection connection;
    CallableStatement statement;
    CatalogueRepository repository;

    @BeforeEach
    void setUp() throws SQLException {
        source = mock(DataSource.class);
        connection = mock(Connection.class);
        statement = mock(CallableStatement.class);
        when(source.getConnection()).thenReturn(connection);
        when(connection.prepareCall(anyString())).thenReturn(statement);
        repository = new CatalogueRepository(source, 5);
    }

    @Test
    void searchBindsParametersAndClosesResources() throws SQLException {
        String keyword = "'; DROP TABLE product; --";
        when(statement.getString(9)).thenReturn("{\"items\":[]}");
        assertThat(repository.search(new CatalogueSearch(keyword, 4, new BigDecimal("1.23"),
                new BigDecimal("999.99"), true, "price_asc", 2, 12))).isEqualTo("{\"items\":[]}");
        verify(connection).prepareCall("{call sp_catalogue_search(?,?,?,?,?,?,?,?,?)}");
        verify(statement).setObject(1, keyword, Types.VARCHAR);
        verify(statement).setObject(2, 4, Types.INTEGER);
        verify(statement).setObject(3, new BigDecimal("1.23"), Types.DECIMAL);
        verify(statement).setObject(4, new BigDecimal("999.99"), Types.DECIMAL);
        verify(statement).setInt(5, 1);
        verify(statement).setString(6, "price_asc");
        verify(statement).setInt(7, 2);
        verify(statement).setInt(8, 12);
        verify(statement).registerOutParameter(9, Types.VARCHAR);
        verify(statement).setQueryTimeout(5);
        verify(statement).close();
        verify(connection).close();
    }

    @Test
    void nullFiltersAreBoundAsSqlNulls() throws SQLException {
        repository.search(new CatalogueSearch(null,null,null,null,false,"name_asc",1,12));
        verify(statement).setObject(1, null, Types.VARCHAR);
        verify(statement).setObject(2, null, Types.INTEGER);
        verify(statement).setObject(3, null, Types.DECIMAL);
        verify(statement).setObject(4, null, Types.DECIMAL);
    }

    @Test
    void categoryAndDetailCallSignatures() throws SQLException {
        repository.categories();
        repository.product(3);
        verify(connection).prepareCall("{call sp_catalogue_categories(?)}");
        verify(connection).prepareCall("{call sp_catalogue_product_detail(?,?)}");
        verify(statement).registerOutParameter(1, Types.VARCHAR);
        verify(statement).registerOutParameter(2, Types.VARCHAR);
        verify(statement).setInt(1, 3);
    }

    @ParameterizedTest
    @CsvSource({"45004,404", "45000,400", "08001,503", "42000,500"})
    void mapsSqlStatesWithoutExposingSql(String state, int status) throws SQLException {
        when(statement.execute()).thenThrow(new SQLException("sensitive SQL", state));
        assertThatThrownBy(() -> repository.product(3)).isInstanceOfSatisfying(CatalogueException.class,
                exception -> {
                    assertThat(exception.status().value()).isEqualTo(status);
                    assertThat(exception.getMessage()).doesNotContain("sensitive SQL");
                });
        verify(statement).close();
        verify(connection).close();
    }

    @Test
    void timeoutMapsTo503() throws SQLException {
        when(statement.execute()).thenThrow(new SQLTimeoutException("timeout"));
        assertThatThrownBy(repository::categories).isInstanceOfSatisfying(CatalogueException.class,
                exception -> assertThat(exception.status().value()).isEqualTo(503));
    }

    @Test
    void connectionFailureMapsTo503() throws SQLException {
        when(source.getConnection()).thenThrow(new SQLNonTransientConnectionException("offline", "08001"));
        assertThatThrownBy(repository::categories).isInstanceOfSatisfying(CatalogueException.class,
                exception -> assertThat(exception.status().value()).isEqualTo(503));
        verifyNoInteractions(statement);
    }

    @Test
    void poolTimeoutWithoutSqlStateMapsTo503() throws SQLException {
        when(source.getConnection()).thenThrow(new SQLTransientConnectionException("Pool exhausted"));
        assertThatThrownBy(repository::categories).isInstanceOfSatisfying(CatalogueException.class,
                exception -> assertThat(exception.status().value()).isEqualTo(503));
    }
}
