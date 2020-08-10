<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class DurationValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";
    const PATTERN = "/^([\-\+])?P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+(?:\.[0-9]+)?)?S)?)$/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Duration $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
