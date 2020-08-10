<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class FloatValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";
    const PATTERN = "/[-+]?[0-9]*\.?[0-9]+/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Float $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
