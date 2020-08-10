<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class AnyURIValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\AnyURI $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {

    }

}
