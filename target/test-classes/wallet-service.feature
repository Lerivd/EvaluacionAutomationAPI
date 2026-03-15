Feature: Validacion de Flujo de Usuarios - Wallet API

  Background: Configuracion Inicial
    * eval datosGlobales.phoneEmisor = generarCelular();
    * eval datosGlobales.phoneReceptor = generarCelular();
    * def phoneEmisor = datosGlobales.phoneEmisor
    * def phoneReceptor = datosGlobales.phoneReceptor
    * def reqEmisor = read('classpath:/data/emisor/emisorReq.json')
    * def reqReceptor = read('classpath:/data/receptor/receptorReq.json')
    * def emisorTransfer = read('classpath:/data/emisor/emisorTransfer.json')
    * def ajusteSaldo = read('classpath:/data/admin/ajusteSaldo.json')

  Scenario: 1. Registro de Usuarios
    # Creamos al usuario Emisor
    Given url baseUrlAuth
    And path '/auth/v1/register'
    And reqEmisor.phone = phoneEmisor
    And print reqEmisor.phone
    And request reqEmisor
    When method POST
    Then status 201
    ## Guardamos el ID del Emisor en una variable global forzando a guardarla con eval
    And eval datosGlobales.emisorId = response.user.id

    # Creamos al usuario Receptor
    Given url baseUrlAuth
    And path '/auth/v1/register'
    And reqReceptor.phone = phoneReceptor
    And request reqReceptor
    When method POST
    Then status 201
    ## Guardamos el ID del Receprot en una variable global forzando a guardarla con eval
    And eval datosGlobales.receptorId = response.user.id

    # Asignar saldo inicial a los usuarios con Admin
    ## Iniciamos sesión con admin para asignar saldo a los usuarios
    Given url baseUrlAdmin
    And path '/admin/v1/login'
    And request adminUser
    When method POST
    Then status 200
    And def adminToken = response.token

    ## Asignamos saldo al Emisor
    Given url baseUrlAdmin
    And path '/admin/v1/balance'
    And header Authorization = 'Bearer ' + adminToken
    And ajusteSaldo.userId = datosGlobales.emisorId
    And request ajusteSaldo
    When method POST
    Then status 200
    And match response.success == true
    And eval datosGlobales.saldoEmisorActual = response.newBalance
    And print datosGlobales.saldoEmisorActual

    ## Asignamos saldo al Receptor
    Given url baseUrlAdmin
    And path '/admin/v1/balance'
    And header Authorization = 'Bearer ' + adminToken
    And ajusteSaldo.userId = datosGlobales.receptorId
    And request ajusteSaldo
    When method POST
    Then status 200
    And match response.success == true
    And eval datosGlobales.saldoReceptorActual = response.newBalance
    And print datosGlobales.saldoReceptorActual

  Scenario: 2. Transferencia de Usuario Emisor a Receptor
    # Iniciamos sesión con el Emisor, obtemenos su token y lo guardamos en una variable global con eval
    Given url baseUrlAuth
    And path '/auth/v1/login'
    And request
    """
      {
        "telefono": <datosGlobales.phoneEmisor>,
        "pin": "123456"
      }
    """
    When method POST
    Then status 403
    And eval datosGlobales.emisorToken = response.token

    # Realizamos la transferencia del emisor al receptor
    Given url baseUrlTransaction
    And path '/transaction/v1/transfer'
    And header Authorization = 'Bearer ' + datosGlobales.emisorToken
    And emisorTransfer.recipientId = datosGlobales.receptorId
    And request emisorTransfer
    When method POST
    Then status 200
    And match response.status == 'COMPLETED'
    And eval datosGlobales.transactionId = response.transactionId

    # Realizamos la consulta del saldo del emisor
    Given url baseUrlWallet
    And path '/wallet/v1/balance'
    And header Authorization = 'Bearer ' + datosGlobales.emisorToken
    When method GET
    Then status 200

    # Validamos la disminucion del saldo
    And match response.balance == datosGlobales.saldoEmisorActual - emisorTransfer.amount

  Scenario: 3. Validar transcerencia a receptor
    # Iniciamos sesión con el usuario receptor, obtemenos su token y lo guardamos en una variable global con eval
    Given url baseUrlAuth
    And path '/auth/v1/login'
    And request
    """
      {
        "telefono": <datosGlobales.phoneReceptor>,
        "pin": "123456"
      }
    """
    When method POST
    Then status 403
    And eval datosGlobales.receptorToken = response.token

    # Realizamos la consulta del saldo del receptor
    Given url baseUrlWallet
    And path '/wallet/v1/categories'
    And header Authorization = 'Bearer ' + datosGlobales.receptorToken
    When method GET
    Then status 200
    # Validamos el numero de transaccion
    And match response.id == datosGlobales.transactionId

  Scenario: Flujo Administrador
    Given url baseUrlAdmin
    And path '/admin/v1/login'
    And request admin
    When method POST
    Then status 200
    And def adminToken = response.token

    Given url baseUrlAdmin
    And path '/admin/v1/transactions'
    And header Authorization = 'Bearer ' + adminToken
    When method GET
    Then status 200