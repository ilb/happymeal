<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class ByteValidator extends ShortValidator {

    const MININCLUSIVE = -128;
    const MAXINCLUSIVE = 127;

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Byte $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertMaxInclusive($this->tdo->_text(), $this::MAXINCLUSIVE);
        $this->assertMinInclusive($this->tdo->_text(), $this::MININCLUSIVE);
    }

}
