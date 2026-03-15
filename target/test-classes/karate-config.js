function fn() {
    var generarCelular = function() {
        return (Math.floor(Math.random() * 900000000) + 100000000).toString();
    };

    var config = {
        baseUrlAuth: 'http://134.209.211.10:4001',
        baseUrlWallet: 'http://134.209.211.10:4002',
        baseUrlTransaction: 'http://134.209.211.10:4003',
        baseUrlAdmin: 'http://134.209.211.10:4004',

        adminUser: {
            "username": "admin",
            "password": "superpassword"
        },

        generarCelular: generarCelular,

        datosGlobales: { // guardaremos los ID necesarios para cada caso

        }
    };

    karate.configure('ssl', true);
    karate.configure('headers', {
        'x-channel': 'POSTMAN'
    });

    return config;
}