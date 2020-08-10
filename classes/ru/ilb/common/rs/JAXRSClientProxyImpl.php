<?php

/** eav 24.12.14 13:40 */

namespace ru\ilb\common\rs;

use ru\ilb\common\rs\JAXRSClientProxy;

class JAXRSClientProxyImpl implements JAXRSClientProxy {

    /**
     * @var string URL ресурса
     */
    protected $baseUrl;

    /**
     * @var \Curl_Config объект класса конфигурации CURL-а
     */
    protected $curlConfig;

    /**
     * @var array headers
     */
    protected $headers = null;

    /**
     * Сохраняет URL ресурса
     * @param string $baseUrl URL ресурса
     */
    public function setBaseUrl($baseUrl) {
        $this->baseUrl = $baseUrl;
    }

    /**
     * Сохраняет объект класса конфигурации CURL-а
     * @param \Curl_Config $curlConfig объект класса конфигурации CURL-а
     */
    public function setCurlConfig(\Curl_Config $curlConfig) {
        $this->curlConfig = $curlConfig;
    }

    /**
     * Сохраняет headers
     * @param array $headers
     */
    public function setHeaders($headers) {
        $this->headers = $headers;
    }

}
