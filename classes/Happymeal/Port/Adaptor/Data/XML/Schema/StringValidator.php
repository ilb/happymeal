<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class StringValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "preserve";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\String $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}
