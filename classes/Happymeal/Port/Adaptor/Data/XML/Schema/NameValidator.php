<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NameValidator extends TokenValidator {

    const PATTERN = "/^[_:A-Za-z][-.:\w]+$/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Name $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validateType() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
