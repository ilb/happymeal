<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class IntValidator extends IntegerValidator {

    const MININCLUSIVE = -2147483648;
    const MAXINCLUSIVE = 2147483647;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Int $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMaxInclusive($this->tdo->_text(), $this::MAXINCLUSIVE);
        $this->assertMinInclusive($this->tdo->_text(), $this::MININCLUSIVE);
    }

}
