<?php

namespace Happymeal\Port\Adaptor\Data\XML\Schema;

class DateTimeValidator extends AnySimpleTypeValidator {

    const WHITESPACE = "collapse";
    const PATTERN = "/^(18|19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])(T| )([01][0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9])$/";

    public function __construct(\Happymeal\Port\Adaptor\Data\XML\Schema\DateTime $tdo, \Happymeal\Port\Adaptor\Data\ValidationHandler $handler) {
        parent::__construct($tdo, $handler);
    }

    public function validate() {
        $this->assertPattern($this->tdo->_text(), $this::PATTERN);
    }

}
