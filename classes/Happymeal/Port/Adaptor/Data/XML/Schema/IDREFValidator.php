<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class IDREFValidator extends NCNameValidator {

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\IDREF $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}
