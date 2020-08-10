<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class LanguageValidator extends TokenValidator {

    const PATTERN = "/[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Language $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
