<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class NCNameValidator extends NameValidator {

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\NCName $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}
