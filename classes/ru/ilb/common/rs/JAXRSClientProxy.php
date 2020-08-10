<?php

/** eav 24.12.14 13:29 */

namespace ru\ilb\common\rs;

interface JAXRSClientProxy {

    /**
     * Сохраняет URL ресурса
     * @param string $baseUrl URL ресурса
     */
    public function setBaseUrl($baseUrl);

    /**
     * Сохраняет объект класса конфигурации CURL-а
     * @param \Curl_Config $curlConfig объект класса конфигурации CURL-а
     */
    public function setCurlConfig(\Curl_Config $curlConfig);
}
