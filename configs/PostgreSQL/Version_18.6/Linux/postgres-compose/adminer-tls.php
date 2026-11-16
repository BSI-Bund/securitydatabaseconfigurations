<?php
// PostgreSQL TLS mode: require a trusted certificate and matching server name.
return new class extends \Adminer\Plugin {
    public function connectSsl() {
        return ["mode" => "verify-full"];
    }
};
