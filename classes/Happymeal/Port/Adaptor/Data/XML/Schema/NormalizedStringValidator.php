<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NormalizedStringValidator extends StringValidator {

    const WHITESPACE = "replace";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\String $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}
