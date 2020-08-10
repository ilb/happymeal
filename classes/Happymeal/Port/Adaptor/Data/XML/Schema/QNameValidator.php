<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class QNameValidator extends AnySimpleTypeValidator {

    const PATTERN = "/^([_A-Za-z][-.\w]+|[_A-Za-z][-.\w]+:[_A-Za-z][-.\w]+)$/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\QName $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        parent::validate();
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
