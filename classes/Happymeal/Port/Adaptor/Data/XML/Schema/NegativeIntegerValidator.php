<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NegativeIntegerValidator extends NonPositiveIntegerValidator {

    const MAXINCLUSIVE = -1;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\NegativeInteger $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMaxInclusive($this->tdo->_text(), $this::MAXINCLUSIVE);
    }

}
