<?php

/**
 * @author Борисов В.В.
 * @version $Id: DataType.php 65 2010-11-16 07:11:38Z slavb $
 */

/**
 * @ignore
 */
interface Adaptor_DataType {

    const INT = 0;
    const XSD = 1;
    const SQL = 2;

    public function getValue($mode = CodeGen_DataType::INT);

    public function setValue($value);

    public function __toString();

    public function LogicalToXSD();

    public function LogicalToSQL();

}
