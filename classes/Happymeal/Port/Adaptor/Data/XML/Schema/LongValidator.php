<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class LongValidator extends IntegerValidator {

    const MININCLUSIVE = -9223372036854775808;
    const MAXINCLUSIVE = 9223372036854775807;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Long $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMaxInclusive($this->tdo->_text(), $this::MAXINCLUSIVE);
        $this->assertMinInclusive($this->tdo->_text(), $this::MININCLUSIVE);
    }

}
