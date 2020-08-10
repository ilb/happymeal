<?php

/**
 * @author Борисов В.В.
 * @version $Id: Array.php 258 2013-05-17 12:51:12Z slavb $
 */

/**
 * @ignore
 */
interface Adaptor_Array {

    public function fromArray($row, $mode = Adaptor_DataType::SQL);
    //public function toArray($mode = Adaptor_DataType::SQL);
}
