<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NonNegativeIntegerValidator extends IntegerValidator {

    const MININCLUSIVE = 0;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\NegativeInteger $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMinInclusive($this->tdo->_text(), $this::MININCLUSIVE);
    }

}
