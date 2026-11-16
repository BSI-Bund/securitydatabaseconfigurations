<?php
// Force verified TLS for MySQL/MariaDB connections made through Adminer.
return new class extends \Adminer\Plugin {
    public function connectSsl() {
        return [
            'key' => null,
            'cert' => null,
            'ca' => '/etc/adminer/tls/ca-cert.pem',
            'verify' => true,
        ];
    }
};
