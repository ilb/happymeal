<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class TimeValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";
    const PATTERN = "/^([01][0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9])$/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Time $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
