<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class TokenValidator extends NormalizedStringValidator {

    const WHITESPACE = "collapse";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\Token $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

}
