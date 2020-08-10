<?php

/** eav 24.12.14 14:29 */

namespace ru\ilb\common\rs;

class JAXRSClientFactory {

    /**
     * @param $baseUrl URL веб-сервиса
     * @param $className имя класса
     * @param \Curl_Config $curlConfig объект класса конфигурации CURL-а
     * @throws \Exception переданный класс не наследует интерфейс JAXRSClientProxy
     * @return экземпляр класса
     */
    static public function create($baseUrl, $curlConfig, $className) {
        $obj = new $className();
        if (!$obj instanceof JAXRSClientProxy) {
            throw new \Exception('Класс не наследует интерфейс JAXRSClientProxy');
        }
        $obj->setBaseUrl($baseUrl);
        $obj->setCurlConfig($curlConfig);
        return $obj;
    }

}
