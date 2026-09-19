Feature: GoRest Users API
  Automatiza el conjunto de APIs de usuarios de https://gorest.co.in
  (List, Create, Update, Delete). Cada escenario valida el status code
  esperado y al menos un assert adicional sobre el cuerpo de la respuesta.

  Background:
    # Las cabeceras (Accept, Content-Type, Authorization Bearer) se aplican de
    # forma global en karate-config.js mediante "configure headers", por lo que
    # persisten en todas las peticiones de cada escenario.
    * url baseUrl

  @list
  Scenario: List users returns a non-empty list of users
    Given path 'users'
    When method GET
    Then status 200
    # Assert 1: la respuesta es un arreglo
    And match response == '#[_ >= 0]'
    # Assert 2: cada usuario tiene los campos esperados
    And match each response contains { id: '#number', name: '#string', email: '#string', status: '#string' }

  @create
  Scenario: Create a new user
    * def uniqueEmail = 'tenali.ramakrishna.' + java.lang.System.currentTimeMillis() + '@15ce.com'
    Given path 'users'
    And request { name: 'Tenali Ramakrishna', gender: 'male', email: '#(uniqueEmail)', status: 'active' }
    When method POST
    Then status 201
    # Assert 1: se generó un id numérico
    And match response.id == '#number'
    # Assert 2: los datos enviados se reflejan en la respuesta
    And match response.name == 'Tenali Ramakrishna'
    And match response.email == uniqueEmail
    And match response.status == 'active'

  @update
  Scenario: Update an existing user
    # Primero creamos un usuario para poder actualizarlo (id dinámico)
    * def newEmail = 'update.user.' + java.lang.System.currentTimeMillis() + '@15ce.com'
    Given path 'users'
    And request { name: 'Original Name', gender: 'male', email: '#(newEmail)', status: 'active' }
    When method POST
    Then status 201
    * def userId = response.id

    # GoRest puede tardar unos milisegundos en propagar el usuario recién creado,
    # por lo que esperamos (retry) hasta que sea consultable antes de actualizar.
    Given path 'users', userId
    And retry until responseStatus == 200
    When method GET
    Then status 200

    # Ahora actualizamos ese usuario
    * def updatedEmail = 'allasani.peddana.' + java.lang.System.currentTimeMillis() + '@15ce.com'
    Given path 'users', userId
    And request { name: 'Allasani Peddana', email: '#(updatedEmail)', status: 'active' }
    When method PATCH
    Then status 200
    # Assert 1: el nombre fue actualizado
    And match response.name == 'Allasani Peddana'
    # Assert 2: el email fue actualizado y el id se conserva
    And match response.email == updatedEmail
    And match response.id == userId

  @delete
  Scenario: Delete an existing user
    # Creamos un usuario para luego eliminarlo (id dinámico)
    * def delEmail = 'delete.user.' + java.lang.System.currentTimeMillis() + '@15ce.com'
    Given path 'users'
    And request { name: 'To Be Deleted', gender: 'female', email: '#(delEmail)', status: 'active' }
    When method POST
    Then status 201
    * def userId = response.id

    # Esperamos (retry) a que el usuario sea consultable antes de eliminarlo,
    # para evitar 404 por propagación del recurso recién creado.
    Given path 'users', userId
    And retry until responseStatus == 200
    When method GET
    Then status 200

    # Eliminamos el usuario
    Given path 'users', userId
    When method DELETE
    # Assert 1: la eliminación responde 204 (No Content)
    Then status 204

    # Assert 2: al consultar el usuario eliminado debe responder 404
    Given path 'users', userId
    When method GET
    Then status 404
