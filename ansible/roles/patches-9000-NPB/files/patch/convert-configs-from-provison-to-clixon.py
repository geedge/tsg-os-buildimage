import os
import sys
import re
import yaml
import xml.etree.ElementTree as ET
import xml.dom.minidom
import argparse

class YamlReader:
    def __init__(self):
        pass

    def read_configs_from_directory(self, directroy):
        configs = {}

        if self.__path_is_exsit(directroy):
            sorted_filenames = self.__get_sorted_filenames(directroy)
            for filename in sorted_filenames:
                filepath = os.path.join(directroy, filename)
                configs_one_file = self.read_configs_from_file(filepath)
                configs.update(configs_one_file)

        return configs

    def read_configs_from_file(self, file_path):
        configs = {}
        
        if self.__path_is_exsit(file_path):
            with open(file_path, 'r') as f:
                load_configs = yaml.safe_load(f)
                if load_configs is not None:
                    configs = load_configs 

        return configs
        
    def __get_sorted_filenames(self, directory):
        filenames = []
        sorted_filenames = []
        
        for filename in os.listdir(directory):
            if filename.endswith('.yaml') or filename.endswith('.yml'):
                filenames.append(filename)
        
        sorted_filenames = sorted(filenames)
        return sorted_filenames

    def __path_is_exsit(self, file_path):
        if os.path.exists(file_path):
            return True
        else:
            return False

class KeyPathParser:
    def __init__(self):
        pass
    
    def read_keys_from_key_path(self, key_path):
        keys = key_path.split('.')
        return keys

    def convert_key_path_to_xml_tag_path(self, key_path):
        tag_path = "./"
        tag_path += key_path.replace(".", "/")
        return tag_path

class ProvisionConfigsLoader:
    def __init__(self, default_config_path, config_path, config_dir_path):
        self.__merged_configs = {}
        self.default_config_path = default_config_path
        self.config_path = config_path
        self.config_dir_path = config_dir_path
        self.__load_configs()
        self.key_path_parser = KeyPathParser()

    def __load_configs(self):
        yaml_reader = YamlReader()
        configs = yaml_reader.read_configs_from_file(self.default_config_path)
        self.__update_merged_configs(configs)

        configs = yaml_reader.read_configs_from_file(self.config_path)
        self.__update_merged_configs(configs)
        
        configs = yaml_reader.read_configs_from_directory(self.config_dir_path)
        self.__update_merged_configs(configs)

    def __update_merged_configs(self, configs):
        # self.__merged_configs.update(configs)
        self.__deep_update(self.__merged_configs, configs)

    def __deep_update(self, dest, src):
        for key, value in src.items():
            if key in dest and isinstance(dest[key], dict) and isinstance(value, dict):
                self.__deep_update(dest[key], value)
            else:
                dest[key] = value


    def read_configs_value_by_key_path(self, key_path):
        nested_keys = self.key_path_parser.read_keys_from_key_path(key_path)
        value = self.__merged_configs
        try:
            for key in nested_keys:
                value = value[key]
            return value 
        except KeyError:
            return None

    def print_configs(self):
        print(self.__merged_configs)

class XmlBuilder:
    def __init__(self):
        pass

    def build_element_by_tag(self, tag):
        element = ET.Element(tag)
        return element

    def build_element_by_tag_and_text(self, tag, text):
        element = ET.Element(tag)
        element.text = text
        return element

    def append_element_child_to_parent(self, child, parent):
        if child is not None and parent is not None:
            parent.append(child)

    def set_element_attribute(self, element, key, value):
        element.set(key, value)
        return element

    def print_element(self, element):
        xml_str = ET.tostring(element, encoding='utf8', method='xml').decode()
        # xml_str = re.sub(r"<\?xml.*\?>\n", "", xml_str)
        # print(xml_str)
        dom = xml.dom.minidom.parseString(xml_str)
        formatted_xml = dom.toprettyxml()
        formatted_xml = re.sub(r"<\?xml.*\?>\n", "", formatted_xml)
        formatted_xml = formatted_xml.replace("\t", "    ")
        print(formatted_xml)

    def append_child_element_with_text(self, parent, tag, text):
        element = self.build_element_by_tag_and_text(tag, text)
        self.append_element_child_to_parent(element, parent)

    def build_base_elements_tree(self, parent_tag, childs_tag_and_text: dict):
        root = self.build_element_by_tag(parent_tag)
        for tag, value in childs_tag_and_text.items():
            self.append_child_element_with_text(root, tag, value)
        return root        

    def build_elements_by_string(self, str):
        return ET.fromstring(str)
        

class ConfigPathConverter:
    def __init__(self):
        self.__config_path_clixon_to_provision = {
            "cm.connectivity.local_cache": "feature.enable_policy_local_cache",
            "overload_protection.enable": "feature.enable_stream_bypass_under_ddos",
            
            "firewall.enable": "firewall.enable",
            "decoders.DTLS": "firewall.enable_dtls",
            "decoders.SIP": "firewall.enable_sip",

            "proxy.enable": "proxy.enable",
            
            "transaction_record.enable_dns": "sessionrecord.enable_dns_record",
            "voip_record.enable_rtp": "sessionrecord.enable_rtp_record",
            "firewall.logs.contains_app_id.enable": "sessionrecord.enable_contains_app_id",
            "firewall.logs.contains_dns_resource_record.enable": "sessionrecord.enable_contains_dns_resource_record",
            
            "packet_capture.enable": "capturepacket.enable",
            
            "ddos_event.enable": "ddossketch.enable",
            "ddos_event.tcp_traffic_report_ratio": "ddossketch.tcp_flood_report_thresh",
            "ddos_event.udp_traffic_report_ratio": "ddossketch.udp_flood_report_thresh",
            "ddos_event.icmp_traffic_report_ratio": "ddossketch.icmp_flood_report_thresh",
            "ddos_event.dns_traffic_report_ratio": "ddossketch.dns_flood_report_thresh",

            "appsketch.context_based_detector": "app.identify_by.user_defined_signature",
            "appsketch.qdpi_detector": "app.identify_by.builtin_app_engine",

            "coredump.format": "coredump.format",
            "coredump.storage": "coredump.collect",
            "coredump.sentry_url": "coredump.sentry_url",

            "session_manager.tcp_session_max": "advanced_settings.stream_tcp_max",
            "session_manager.tcp_session_timeout_in_sec": "advanced_settings.stream_tcp_timeout",
            "session_manager.udp_session_max": "advanced_settings.stream_udp_max",
            "session_manager.udp_session_timeout_in_sec": "advanced_settings.stream_udp_timeout",
            "overload_protection.detect_threshold_cpu_usages": "advanced_settings.stream_bypass_trigger_cpu_usage",
           
            "cm.direct.address": "cm.policy_server.address",
            "cm_policy_local_cache.cm_addresses.address": "cm.policy_server.address",
            "cm.direct.port": "cm.policy_server.port",
            "cm_policy_local_cache.cm_addresses.port": "cm.policy_server.port",

            "session_distribution_policy.mode": "session_distribution_policy.mode",
            "session_distribution_policy.hash_key": "session_distribution_policy.hash_key",

            "olap.kafka_brokers.addresses": "olap.kafka_broker.address_list",
            
            "service_function.vsys_id": "vsys_id",
            
            "system.consul_agent.mode": "consul_agent.mode",
            "system.consul_agent.encrypt": "consul_agent.encrypt",
            "system.consul_agent.datacenter": "consul_agent.datacenter",
            # "system.consul_agent.node_name": "consul_agent.bootstrapExpect",
            "system.consul_agent.bootstrapExpect": "consul_agent.bootstrapExpect",
            "system.consul_agent.join": "consul_agent.join",
            
            "shaping.enable": "shaping.enable",
            
            "system.device_tags": "device.tags",
            
            "session_id_generator.snowflake_worker_id_base": "session_id_generator.snowflake_worker_id_base",
            "session_id_generator.snowflake_worker_id_offset": "session_id_generator.snowflake_worker_id_offset"
        }

    def convert_config_path_from_clixon_to_provision(self, clixon_config_path):
        return self.__config_path_clixon_to_provision.get(clixon_config_path)

class XmlPathBuilder:
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder:XmlBuilder, config_path_converter:ConfigPathConverter):
        self.provision_config_loader = provision_config_loader
        self.xml_builder = xml_builder
        self.config_path_converter = config_path_converter
        self.namespaces = {"xmlns": "urn:yang:tsg-os-mgnt-srv"}
    
    # def set_element_attributes(self, element):
    #     for key, value in self.namespaces.items():
    #         self.xml_builder.set_element_attribute(element, key, value)
    
    def read_value_by_clixon_config_path(self, clixon_config_path):
        value = None

        provision_config_path = self.config_path_converter.convert_config_path_from_clixon_to_provision(clixon_config_path)
        if provision_config_path is not None:
           value = self.provision_config_loader.read_configs_value_by_key_path(provision_config_path)

        return value

class XmlPathTemplateBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder,config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)

    def build_xml_path_root(self):
        root = self.xml_builder.build_element_by_tag("template")

        #super().set_element_attributes(root)
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:yang:tsg-os-mgnt-srv")
        
    
        self.xml_builder.append_child_element_with_text(root, "name", "tsg_traffic_engine_default")
        self.xml_builder.append_child_element_with_text(root, "type", "tsg_traffic")

        external_resources = self.__build_xml_path_external_resources()
        self.xml_builder.append_element_child_to_parent(external_resources, root)

        decoders = self.__build_path_decoder()
        self.xml_builder.append_element_child_to_parent(decoders, root)

        firewall = self.__build_xml_path_firewall()
        self.xml_builder.append_element_child_to_parent(firewall, root)
        
        appsketch = self.__build_xml_path_appsketch()
        self.xml_builder.append_element_child_to_parent(appsketch, root)

        transaction_record = self.__build_xml_path_transaction_record()
        self.xml_builder.append_element_child_to_parent(transaction_record, root)

        voip_record = self.__build_xml_path_voip_record()
        self.xml_builder.append_element_child_to_parent(voip_record, root)
        
        ddos_event = self.__build_xml_path_ddos_event()
        self.xml_builder.append_element_child_to_parent(ddos_event, root)

        traffic_mirror = self.__build_xml_path_traffic_mirror()
        self.xml_builder.append_element_child_to_parent(traffic_mirror, root)

        packaget_capture = self.__build_xml_path_packet_capture()
        self.xml_builder.append_element_child_to_parent(packaget_capture, root)

        shaping = self.__build_xml_path_shaping()
        self.xml_builder.append_element_child_to_parent(shaping, root)

        proxy = self.__build_xml_path_proxy()
        self.xml_builder.append_element_child_to_parent(proxy, root)
        
        service_chaining = self.__build_xml_path_service_chaining()
        self.xml_builder.append_element_child_to_parent(service_chaining, root)
        
        session_manager = self.__build_xml_path_session_manager()
        self.xml_builder.append_element_child_to_parent(session_manager, root)
        
        overload_protection = self.__build_xml_path_overload_protection()
        self.xml_builder.append_element_child_to_parent(overload_protection, root)

        return root


    def __build_xml_path_external_resources(self):
        root = self.xml_builder.build_element_by_tag("external_resources")
        
        cm = self.__build_xml_path_external_resources_cm()
        self.xml_builder.append_element_child_to_parent(cm, root)

        # sd = self.__build_xml_path_external_resources_sd()
        # self.xml_builder.append_element_child_to_parent(sd, root)

        olap = self.__build_xml_path_external_resources_olap()
        self.xml_builder.append_element_child_to_parent(olap, root)

        return root        

    def __build_xml_path_external_resources_cm(self):
        root = self.xml_builder.build_element_by_tag("cm")

        provsion_local_cache_enable = super().read_value_by_clixon_config_path("cm.connectivity.local_cache")
        if provsion_local_cache_enable is not None and provsion_local_cache_enable == 1:
            self.xml_builder.append_child_element_with_text(root, "connectivity", "local_cache")
            local_cache = self.xml_builder.build_base_elements_tree("local_cache", {"cache_name": "cm0"})
            self.xml_builder.append_element_child_to_parent(local_cache, root)
        else:
            self.xml_builder.append_child_element_with_text(root, "connectivity", "direct")

            childs_tag_and_text = {"address": "127.0.0.1", "port": "7002"}
            provision_cm_address = super().read_value_by_clixon_config_path("cm.direct.address")
            if provision_cm_address is not None:
                childs_tag_and_text["address"] = str(provision_cm_address)

            provision_cm_port = super().read_value_by_clixon_config_path("cm.direct.port")
            if provision_cm_port is not None:
                childs_tag_and_text["port"] = str(provision_cm_port)

            direct = self.xml_builder.build_base_elements_tree("direct", childs_tag_and_text)
            self.xml_builder.append_element_child_to_parent(direct, root)

        return root

    # def __build_xml_path_external_resources_sd(self):
    #     root = self.xml_builder.build_element_by_tag("sd")

    #     self.xml_builder.append_child_element_with_text(root, "enable", "no")
    #     self.xml_builder.append_child_element_with_text(root, "connectivity", "direct")

    #     direct = self.xml_builder.build_base_elements_tree("direct", {"address": "127.0.0.1", "port": "6379"})
    #     self.xml_builder.append_element_child_to_parent(direct, root)

    #     return root

    def __build_xml_path_external_resources_olap(self):
        root = self.xml_builder.build_element_by_tag("olap")

        kafka_brokers = self.xml_builder.build_element_by_tag("kafka_brokers")
        self.xml_builder.append_element_child_to_parent( kafka_brokers, root)

        provision_address_list = super().read_value_by_clixon_config_path("olap.kafka_brokers.addresses")

        if provision_address_list is not None:
            self.xml_builder.append_child_element_with_text(kafka_brokers, "sasl_username", "admin")
            self.xml_builder.append_child_element_with_text(kafka_brokers, "sasl_password", "galaxy2019")
            for address in provision_address_list:
                ip, port = address.split(':')
                parent_tag = "addresses"
                childs_tag_with_text = {
                    "address": str(ip),
                    "port": str(port)
                }
                addresses = self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_with_text)
                self.xml_builder.append_element_child_to_parent(addresses, kafka_brokers)
        else:
            addresses = addresses = self.xml_builder.build_base_elements_tree("addresses", {"address": "127.0.0.1", "port": "9094"})
            self.xml_builder.append_element_child_to_parent(addresses, kafka_brokers)
        return root


    def __build_path_decoder(self):
        parent_tag = "decoders"
        childs_tag_and_text = {
            "DNS": "yes",
            "QUIC": "yes",
            "HTTP": "yes",
            "HTTP_GZIP": "yes",
            "MAIL": "yes",
            "MAIL_BASE64": "yes",
            "FTP": "yes",
            "SSL": "yes",
            "SSL_CERT": "yes",
            "RTP": "yes",
            "SIP": "yes",
            "SSH": "yes",
            "SOCKS": "yes",
            "STRATUM": "yes",
            "RDP": "yes",
            "DTLS": "yes"
        }

        provision_decoders_dtls = super().read_value_by_clixon_config_path("decoders.DTLS")
        if provision_decoders_dtls is not None and provision_decoders_dtls != 1:
            childs_tag_and_text["DTLS"] = "no"

        provision_decoders_sip = super().read_value_by_clixon_config_path("decoders.SIP")
        if provision_decoders_sip is not None and provision_decoders_sip != 1:
            childs_tag_and_text["SIP"] = "no"

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)


    def __build_xml_path_firewall(self):
        root = self.xml_builder.build_element_by_tag("firewall")
        
        provision_firewall_enable = super().read_value_by_clixon_config_path("firewall.enable")
        if provision_firewall_enable is not None and provision_firewall_enable != 1:
            self.xml_builder.append_child_element_with_text(root, "enable", "no")
        else:
            self.xml_builder.append_child_element_with_text(root, "enable", "yes")
        
        logs = self.xml_builder.build_element_by_tag("logs")
        self.xml_builder.append_element_child_to_parent(logs, root) 

        provision_enable_contains_app_id = super().read_value_by_clixon_config_path("firewall.logs.contains_app_id.enable")
        child_contains_app_id = {"enable": "no"}
        if provision_enable_contains_app_id is not None and provision_enable_contains_app_id == 1:
            child_contains_app_id = {"enable": "yes"}
        contains_app_id = self.xml_builder.build_base_elements_tree("contains_app_id", child_contains_app_id)
        self.xml_builder.append_element_child_to_parent(contains_app_id, logs)

        provision_enable_contains_dns_resource_record = super().read_value_by_clixon_config_path("firewall.logs.contains_dns_resource_record.enable")
        child_contains_dns_resource_record = {"enable": "no"} 
        if provision_enable_contains_dns_resource_record is not None and provision_enable_contains_dns_resource_record == 1:
            child_contains_dns_resource_record = {"enable": "yes"}
        contains_dns_resource_record = self.xml_builder.build_base_elements_tree("contains_dns_resource_record", child_contains_dns_resource_record)
        self.xml_builder.append_element_child_to_parent(contains_dns_resource_record, logs)

        return root
        
    def __build_xml_path_appsketch(self):
        parent_tag = "appsketch"
        childs_tag_and_text = {
           "enable": "yes",
           "qdpi_detector": "yes",
           "context_based_detector": "yes"
        }

        provision_context_based_detector = super().read_value_by_clixon_config_path("appsketch.context_based_detector")
        if provision_context_based_detector is not None and provision_context_based_detector != 1:
            childs_tag_and_text["context_based_detector"] = "no"

        provision_qdpi_detector = super().read_value_by_clixon_config_path("appsketch.qdpi_detector")
        if provision_qdpi_detector is not None and provision_qdpi_detector != 1:
            childs_tag_and_text["qdpi_detector"] = "no"

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)


    def __build_xml_path_transaction_record(self):
        parent_tag = "transaction_record"
        childs_tag_and_text = {
           "enable_http": "yes",
           "enable_dns": "yes",
           "enable_mail": "yes"
        }

        provision_enable_dns_record = super().read_value_by_clixon_config_path("transaction_record.enable_dns")
        if provision_enable_dns_record is not None and provision_enable_dns_record != 1:
            childs_tag_and_text["enable_dns"] = "no"

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)



    def __build_xml_path_voip_record(self):
        parent_tag = "voip_record"
        childs_tag_and_text = {
           "enable_sip": "yes",
           "enable_rtp": "yes"
        }
        
        provision_enable_rtp_record = super().read_value_by_clixon_config_path("voip_record.enable_rtp")
        
        if provision_enable_rtp_record is not None and provision_enable_rtp_record != 1:
            childs_tag_and_text["enable_rtp"] = "no"
        
        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_ddos_event(self):
        parent_tag = "ddos_event"
        childs_tag_and_text = {
           "enable": "yes",
           "tcp_traffic_report_ratio": "0.0008",
           "udp_traffic_report_ratio": "0.0008",
           "icmp_traffic_report_ratio": "0.0008",
           "dns_traffic_report_ratio": "0.0008"
        }

        provision_enable = super().read_value_by_clixon_config_path("ddos_event.enable")
        if provision_enable is not None and provision_enable != 1:
            childs_tag_and_text["enable"] = "no"

        provision_tcp_traffic_report_ratio = super().read_value_by_clixon_config_path("ddos_event.tcp_traffic_report_ratio")
        if provision_tcp_traffic_report_ratio is not None:
            childs_tag_and_text["tcp_traffic_report_ratio"] = str(provision_tcp_traffic_report_ratio)

        provision_udp_traffic_report_ratio = super().read_value_by_clixon_config_path("ddos_event.udp_traffic_report_ratio")
        if provision_udp_traffic_report_ratio is not None:
            childs_tag_and_text["udp_traffic_report_ratio"] = str(provision_udp_traffic_report_ratio)

        provision_icmp_traffic_report_ratio = super().read_value_by_clixon_config_path("ddos_event.icmp_traffic_report_ratio")
        if provision_icmp_traffic_report_ratio is not None:
            childs_tag_and_text["icmp_traffic_report_ratio"] = str(provision_icmp_traffic_report_ratio)

        provision_dns_traffic_report_ratio = super().read_value_by_clixon_config_path("ddos_event.dns_traffic_report_ratio")
        if provision_dns_traffic_report_ratio is not None:
            childs_tag_and_text["dns_traffic_report_ratio"] = str(provision_dns_traffic_report_ratio)

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_traffic_mirror(self):
        parent_tag = "traffic_mirror"
        childs_tag_and_text = {
           "enable_raw_traffic": "no",
           "enable_decrypted_traffic": "no"
        }
        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_packet_capture(self):
        childs_tag_and_text = {"enable": "yes"}

        provision_packet_capture = super().read_value_by_clixon_config_path("packet_capture.enable")
        if provision_packet_capture is not None and provision_packet_capture != 1:
           childs_tag_and_text = {"enable": "no"}

        return self.xml_builder.build_base_elements_tree("packet_capture", childs_tag_and_text)

    def __build_xml_path_shaping(self):
        childs_with_tags_and_text = {"enable":"no"}

        provision_shaping_enable = super().read_value_by_clixon_config_path("shaping.enable")
        if provision_shaping_enable is not None and provision_shaping_enable == 1:
            childs_with_tags_and_text["enable"] = "yes"
        
        return self.xml_builder.build_base_elements_tree("shaping", childs_with_tags_and_text)

    def __build_xml_path_proxy(self):
        childs_tag_and_text = {"enable": "yes"}
        
        provision_proxy_enable = super().read_value_by_clixon_config_path("proxy.enable")
        if provision_proxy_enable is not None and provision_proxy_enable != 1:
            childs_tag_and_text = {"enable": "no"}
        
        return self.xml_builder.build_base_elements_tree("proxy", childs_tag_and_text)


    def __build_xml_path_service_chaining(self):
        return self.xml_builder.build_base_elements_tree("service_chaining", {"enable": "no"})


    def __build_xml_path_session_manager(self):
        parent_tag = "session_manager"
        childs_tag_and_text = {
           "tcp_session_max": "20021",
           "tcp_session_unordered_pkt_max": "128",
           "tcp_session_timeout_in_sec": "120",
           "udp_session_timeout_in_sec": "60",
           "udp_session_max": "5021",
           "tcp_duplicated_packet_filter": "yes",
           "udp_duplicated_packet_filter": "yes"
        }

        provision_tcp_session_max = super().read_value_by_clixon_config_path("session_manager.tcp_session_max")
        if provision_tcp_session_max is not None:
            childs_tag_and_text["tcp_session_max"] = str(provision_tcp_session_max)

        provision_tcp_session_timeout_in_sec = super().read_value_by_clixon_config_path("session_manager.tcp_session_timeout_in_sec")
        if provision_tcp_session_timeout_in_sec is not None:
            childs_tag_and_text["tcp_session_timeout_in_sec"] = str(provision_tcp_session_timeout_in_sec)
            
        provision_udp_session_max = super().read_value_by_clixon_config_path("session_manager.udp_session_max")
        if provision_udp_session_max is not None:
            childs_tag_and_text["udp_session_max"] = str(provision_udp_session_max)

        provision_udp_session_timeout_in_sec = super().read_value_by_clixon_config_path("session_manager.udp_session_timeout_in_sec")
        if provision_udp_session_timeout_in_sec is not None:
            childs_tag_and_text["udp_session_timeout_in_sec"] = str(provision_udp_session_timeout_in_sec)

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_overload_protection(self):
        childs_tag_and_text = {"enable": "yes"}

        provision_overload_protection_enable = super().read_value_by_clixon_config_path("overload_protection.enable")
        if provision_overload_protection_enable is not None and provision_overload_protection_enable != 1:
            childs_tag_and_text["enable"] = "no"
        
        provision_detect_threshold_cpu_usages = super().read_value_by_clixon_config_path("overload_protection.detect_threshold_cpu_usages")
        if provision_detect_threshold_cpu_usages is not None:
            childs_tag_and_text["detect_threshold_cpu_usages"] = str(provision_detect_threshold_cpu_usages)

        return self.xml_builder.build_base_elements_tree("overload_protection", childs_tag_and_text)

class XmlPathServiceFunctionstBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder, config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)

    def build_xml_path_root(self):
        parent_tag = "service_function"
        childs_tag_and_text = {
           "name": "tsg-traffic-engine-vsys-1",
           "enable": "no",
           "vsys_id": "1"
        }

        provision_vsys_id = super().read_value_by_clixon_config_path("service_function.vsys_id")
        if provision_vsys_id is not None:
            childs_tag_and_text["vsys_id"] = str(provision_vsys_id)
            childs_tag_and_text["name"] = "tsg-traffic-engine-vsys-" + str(provision_vsys_id)
            childs_tag_and_text["enable"] = "yes"

        root = self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)
        #super().set_element_attributes(root)
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:yang:tsg-os-mgnt-srv")

        quotas = self.__build_xml_path_quotas()
        self.xml_builder.append_element_child_to_parent(quotas, root)

        session_id_generator = self.build_xml_format_service_functions_session_id_generator()
        self.xml_builder.append_element_child_to_parent(session_id_generator, root)
        
        settings = self.build_xml_format_service_functions_settings()
        self.xml_builder.append_element_child_to_parent(settings, root)

        return root

    def __build_xml_path_quotas(self):
        parent_tag = "quotas"
        childs_tag_and_text = {
           "firewall_affinity": "5-47",
           "proxy_affinity": "48-55"
        }        
        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def build_xml_format_service_functions_session_id_generator(self):
        parent_tag = "session_id_generator"
        childs_tag_and_text = {
           "snowflake_worker_id_base": "1",
           "snowflake_worker_id_offset": "1"
        }
        
        provision_snowflake_worker_id_base = super().read_value_by_clixon_config_path("session_id_generator.snowflake_worker_id_base")
        if provision_snowflake_worker_id_base is not None:
            childs_tag_and_text["snowflake_worker_id_base"] = str(provision_snowflake_worker_id_base)

        provision_snowflake_worker_id_offset = super().read_value_by_clixon_config_path("session_id_generator.snowflake_worker_id_offset")
        if provision_snowflake_worker_id_offset is not None:
            childs_tag_and_text["snowflake_worker_id_offset"] = str(provision_snowflake_worker_id_offset)

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def build_xml_format_service_functions_settings(self):
        return self.xml_builder.build_base_elements_tree("settings", {"template": "tsg_traffic_engine_default"})

class XmlPathRuleSetBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder,  config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)

    def build_xml_path_root(self):
        # root = self.xml_builder.build_element_by_tag("ruleset")
        childs_with_tag_and_text = {"name": "ruleset_vsys_1"}

        provision_vsys_id = super().read_value_by_clixon_config_path("service_function.vsys_id")
        if provision_vsys_id is not None:
            childs_with_tag_and_text["name"] = "ruleset_vsys_" + str(provision_vsys_id)

        root = self.xml_builder.build_base_elements_tree("ruleset", childs_with_tag_and_text)

        #super().set_element_attributes(root)
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:yang:tsg-os-mgnt-srv")
        ruleset = self.__build_xml_path_rule()
        self.xml_builder.append_element_child_to_parent(ruleset, root)
        return root

    def __build_xml_path_rule(self):
        return self.xml_builder.build_base_elements_tree("rule", {"id": "1"})

class XmlPathServiceFunctionChainBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder, config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)

    def build_xml_path_root(self):
        root = self.xml_builder.build_element_by_tag("service_function_chain")
        #super().set_element_attributes(root)
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:yang:tsg-os-mgnt-srv")
        
        self.xml_builder.append_child_element_with_text(root, "name", "Default")

        index = self.__build_xml_path_index()
        self.xml_builder.append_element_child_to_parent(index, root)
        
        return root

    def __build_xml_path_index(self):
        parent_tag = "index"
        childs_tag_and_text = {
            "id": "1",
            "ruleset": "ruleset_vsys_1",
            "service_function": "tsg-traffic-engine-vsys-1"
        }
        
        provision_vsys_id = super().read_value_by_clixon_config_path("service_function.vsys_id")
        if provision_vsys_id is not None:
            childs_tag_and_text["service_function"] = "tsg-traffic-engine-vsys-" + str(provision_vsys_id)
            childs_tag_and_text["ruleset"] = "ruleset_vsys_" + str(provision_vsys_id)
        
        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

class XmlPathSystemBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder, config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)
    
    def build_xml_path_root(self):
        root = self.xml_builder.build_element_by_tag("system")
        #super().set_element_attributes(root)
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:yang:tsg-os-mgnt-srv")

        self.__append_xml_path_device_tags_to_root(root)

        coredump = self.__build_xml_path_coredump()
        self.xml_builder.append_element_child_to_parent(coredump, root)

        packet_io_engine = self.__build_xml_path_packet_io_engine()
        self.xml_builder.append_element_child_to_parent(packet_io_engine, root)

        session_distribution_policy = self.__build_xml_path_session_distribution_policy()
        self.xml_builder.append_element_child_to_parent(session_distribution_policy, root)
        
        consul_agent = self.__build_xml_path_consul_agent()
        self.xml_builder.append_element_child_to_parent(consul_agent, root)

        cm_policy_local_cache = self.__build_xml_path_cm_policy_local_cache()
        self.xml_builder.append_element_child_to_parent(cm_policy_local_cache, root)

        inject_adapter = self.__build_xml_path_inject_adapter()
        self.xml_builder.append_element_child_to_parent(inject_adapter, root)

        return root
    
    def __append_xml_path_device_tags_to_root(self, root):
        provision_device_tags = super().read_value_by_clixon_config_path("system.device_tags")
        if provision_device_tags is not None:
            for item in provision_device_tags:
                for key, value in item.items():
                    device_tags = self.xml_builder.build_base_elements_tree("device_tags", {"key": key, "value": value})
                    self.xml_builder.append_element_child_to_parent(device_tags, root)
 
    def __build_xml_path_coredump(self):
        parent_tag = "coredump"
        childs_tag_and_text = {
            "format": "minidump",
            "storage": "local"
        }
        
        provision_format = super().read_value_by_clixon_config_path("coredump.format")
        if provision_format is not None:
            childs_tag_and_text["format"] = provision_format
        
        provision_storage = super().read_value_by_clixon_config_path("coredump.storage")
        if provision_storage is not None:
            childs_tag_and_text["storage"] = provision_storage

        provision_sentry_url = super().read_value_by_clixon_config_path("coredump.sentry_url")
        if provision_sentry_url is not None and provision_storage == "sentry":
            childs_tag_and_text["sentry_url"] = provision_sentry_url

        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_packet_io_engine(self):  
        return self.xml_builder.build_base_elements_tree("packet_io_engine", {"enable": "yes"})


    def __build_xml_path_session_distribution_policy(self):
        parent_tag = "session_distribution_policy"
        childs_tag_and_text = {
            "mode": "sym-hash",
            "hash_key": "inner-most-sip-dip-sport-dport"
        }

        provision_mode = super().read_value_by_clixon_config_path("session_distribution_policy.mode")
        if provision_mode is not None:
            childs_tag_and_text["mode"] = provision_mode

        provision_hash_key = super().read_value_by_clixon_config_path("session_distribution_policy.hash_key")
        if provision_hash_key is not None:
            childs_tag_and_text["hash_key"] = provision_hash_key
        
        return self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

    def __build_xml_path_consul_agent(self):
        parent_tag = "consul_agent"
        childs_tag_and_text = {
            "enable": "no",
            "mode": "server",
            "encrypt": "XN0I7fHIY1+yLWm2PjegZ7U93nI/tmzNvtmBtZLuIfo=",
            "bootstrap_expect": "1",
            "datacenter": "dc1"
        }
        
        provision_shaping_enable = super().read_value_by_clixon_config_path("shaping.enable")
        if provision_shaping_enable is not None and provision_shaping_enable == 1:
            childs_tag_and_text["enable"] = "yes"

        provision_mode = super().read_value_by_clixon_config_path("system.consul_agent.mode")
        if provision_mode is not None:
            childs_tag_and_text["mode"] = str(provision_mode)

        provision_encrypt = super().read_value_by_clixon_config_path("system.consul_agent.encrypt")
        if provision_encrypt is not None:
            childs_tag_and_text["encrypt"] = str(provision_encrypt)
        
        provision_datacenter = super().read_value_by_clixon_config_path("system.consul_agent.datacenter")
        if provision_datacenter is not None:
            childs_tag_and_text["datacenter"] = str(provision_datacenter)

        provision_bootstrap_expect = super().read_value_by_clixon_config_path("system.consul_agent.bootstrapExpect")
        if provision_bootstrap_expect is not None:
            childs_tag_and_text["bootstrap_expect"] = str(provision_bootstrap_expect)
        
        root = self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)

        provision_joins = super().read_value_by_clixon_config_path("system.consul_agent.join")
        if provision_joins is not None:
            for item in provision_joins:
                join = self.xml_builder.build_base_elements_tree("join", {"address": item["address"], "port": str(item["port"])})    
                self.xml_builder.append_element_child_to_parent(join, root)
        else:
            join = self.xml_builder.build_base_elements_tree("join", {"address": "127.0.0.1", "port": "8301"})
            self.xml_builder.append_element_child_to_parent(join, root)

        return root

    def __build_xml_path_cm_policy_local_cache(self):
        root = None       
        provsion_local_cache_enable = super().read_value_by_clixon_config_path("cm.connectivity.local_cache")
        
        if provsion_local_cache_enable is not None and provsion_local_cache_enable == 1:
            root = self.xml_builder.build_element_by_tag("cm_policy_local_cache")
            self.xml_builder.append_child_element_with_text(root, "name", "cm0")
            self.xml_builder.append_child_element_with_text(root, "enable", "yes")
            parent_tag = "cm_addresses"
            childs_tag_and_text = {
                "type": "active",
                "address": "127.0.0.1",
                "port": "7002"
            }
            provision_cm_address = super().read_value_by_clixon_config_path("cm_policy_local_cache.cm_addresses.address")

            if provision_cm_address is not None:         
                childs_tag_and_text["address"] = str(provision_cm_address)

            provision_cm_port = super().read_value_by_clixon_config_path("cm_policy_local_cache.cm_addresses.port")
            
            if provision_cm_address is not None:         
                childs_tag_and_text["port"] = str(provision_cm_port)
            
            cm_addresses = self.xml_builder.build_base_elements_tree(parent_tag, childs_tag_and_text)
            self.xml_builder.append_element_child_to_parent(cm_addresses, root)

        return root

    def __build_xml_path_inject_adapter(self):
        return self.xml_builder.build_base_elements_tree("inject_adapter", {"enable": "no"}) 


class XmlPathYangLibraryBuilder(XmlPathBuilder):
    def __init__(self, provision_config_loader:ProvisionConfigsLoader, xml_builder: XmlBuilder, config_path_converter:ConfigPathConverter):
        super().__init__(provision_config_loader, xml_builder, config_path_converter)


    def build_xml_path_root(self):
        root = self.xml_builder.build_element_by_tag("yang-library")
        self.xml_builder.set_element_attribute(root, "xmlns", "urn:ietf:params:xml:ns:yang:ietf-yang-library")
        
        module_set = self.__build_xml_path_module_set()
        self.xml_builder.append_element_child_to_parent(module_set, root)
        
        self.xml_builder.append_child_element_with_text(root, "content-id", "0")
        
        return root
    
    def __build_xml_path_module_set(self):
        root = self.xml_builder.build_element_by_tag("module-set")
        self.xml_builder.append_child_element_with_text(root, "name", "default")
    
        module_childs_tag_and_text = [
            {"name": "clixon-autocli", "revision": "2022-02-11", "namespace": "http://clicon.org/autocli"},
            {"name": "clixon-lib", "revision": "2021-12-05", "namespace": "http://clicon.org/lib"},
            {"name": "clixon-rfc5277", "revision": "2008-07-01", "namespace": "urn:ietf:params:xml:ns:netmod:notification"},

            {"name": "clixon-xml-changelog", "revision": "2019-03-21", "namespace": "http://clicon.org/xml-changelog"},
            {"name": "ietf-datastores", "revision": "2018-02-14", "namespace": "urn:ietf:params:xml:ns:yang:ietf-datastores"},
            {"name": "ietf-inet-types", "revision": "2021-02-22", "namespace": "urn:ietf:params:xml:ns:yang:ietf-inet-types"},

            {"name": "ietf-list-pagination", "revision": "2021-10-25", "namespace": "urn:ietf:params:xml:ns:yang:ietf-list-pagination"},
            {"name": "ietf-list-pagination-nc", "revision": "2021-10-25", "namespace": "urn:ietf:params:xml:ns:yang:ietf-list-pagination-nc"},
            {"name": "ietf-netconf", "revision": "2011-06-01", "namespace": "urn:ietf:params:xml:ns:netconf:base:1.0"},

            {"name": "ietf-netconf-nmda", "revision": "2019-01-07", "namespace": "urn:ietf:params:xml:ns:yang:ietf-netconf-nmda"},            
            {"name": "ietf-netconf-with-defaults", "revision": "2011-06-01", "namespace": "urn:ietf:params:xml:ns:yang:ietf-netconf-with-defaults"},
            {"name": "ietf-origin", "revision": "2018-02-14", "namespace": "urn:ietf:params:xml:ns:yang:ietf-origin"},

            {"name": "ietf-restconf", "revision": "2017-01-26", "namespace": "urn:ietf:params:xml:ns:yang:ietf-restconf"},
            {"name": "ietf-yang-library", "revision": "2019-01-04", "namespace": "urn:ietf:params:xml:ns:yang:ietf-yang-library"},
            {"name": "ietf-yang-metadata", "revision": "2016-08-05", "namespace": "urn:ietf:params:xml:ns:yang:ietf-yang-metadata"},

            {"name": "ietf-yang-types", "revision": "2013-07-15", "namespace": "urn:ietf:params:xml:ns:yang:ietf-yang-types"},
            {"name": "tsg-os-mgnt-srv", "revision": "2024-01-18", "namespace": "urn:yang:tsg-os-mgnt-srv"}
        ]
    
        for item in module_childs_tag_and_text:
            module = self.xml_builder.build_base_elements_tree("module", item)
            self.xml_builder.append_element_child_to_parent(module, root)
        
        return root

class ClixonConfigBuilder:
    def __init__(self, provision_configs_loader: ProvisionConfigsLoader, xml_builder: XmlBuilder, config_path_converter: ConfigPathConverter):
        self.__provision_configs_loader = provision_configs_loader
        self.__xml_builder = xml_builder
        self.__config_path_converter = config_path_converter
        self.__xml_configs = self.__build_xml_configs()
    
    def __build_xml_configs(self):
        root = self.__xml_builder.build_element_by_tag("config")
        
        builders = [
            XmlPathTemplateBuilder,
            XmlPathServiceFunctionstBuilder,
            XmlPathRuleSetBuilder,
            XmlPathServiceFunctionChainBuilder,
            XmlPathSystemBuilder,
            XmlPathYangLibraryBuilder
        ]

        for builder_class in builders:
            builder = builder_class(self.__provision_configs_loader, self.__xml_builder, self.__config_path_converter)
            element = builder.build_xml_path_root()
            self.__xml_builder.append_element_child_to_parent(element, root)

        return root

    def read_xml_configs(self):
        return self.__xml_configs
    
    def print_xml_configs(self):
        self.__xml_builder.print_element(self.__xml_configs)


class CommandParser:
    def __init__(self):
        self.__start_up()

    def __start_up(self):
        parser = argparse.ArgumentParser(description='Provision config converter')

        parser.add_argument("-d", "--default-config", type = str, default = None, help = "The provision default config path.")
        parser.add_argument("-c", "--config", type = str, default = None, help = "The provision config path.")
        parser.add_argument("--config-dir", type = str, default = None, help = "The provision config directory.")
        args = parser.parse_args()
        
        self.__default_config_path = args.default_config
        self.__config_path = args.config
        self.__config_dir = args.config_dir
        
        if self.__default_config_path is None or self.__config_path is None or self.__config_dir is None:
            parser.print_help()
            sys.exit(1)

    def get_default_config_path(self):
        return self.__default_config_path
    
    def get_config_path(self):
        return self.__config_path

    def get_config_dir(self):
        return self.__config_dir

if __name__ == '__main__':
    cmd_parser = CommandParser()
    default_config_path = cmd_parser.get_default_config_path()
    config_path = cmd_parser.get_config_path()
    config_dir_path = cmd_parser.get_config_dir()

    provision_config_loader = ProvisionConfigsLoader(default_config_path, config_path, config_dir_path)    
    xml_builder = XmlBuilder()

    config_path_converter = ConfigPathConverter()
    clixon_config_builder = ClixonConfigBuilder(provision_config_loader, xml_builder, config_path_converter)
    clixon_config_builder.print_xml_configs()
    