<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NonPositiveIntegerValidator extends IntegerValidator {

    const MAXINCLUSIVE = 0;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\NonPositiveInteger $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMaxInclusive($this->tdo->_text(), $this::MAXINCLUSIVE);
    }

}
