import yaml
import os
import sys

PATH_SAMPLE_CONFIG="/opt/tsg/tsg-os-provision/provision.yml.sample"
PATH_INSTANCE_CONFIG="/data/tsg-os-provision/provision.yml"


def obtain_conf_dict(path):
    fd = open(path,'r',encoding="utf-8")
    origin_data = fd.read()
    fd.close()
    data = yaml.load(origin_data,Loader=yaml.Loader)
    if not isinstance(data, dict):
        print("%s format error" %(PATH_SAMPLE_CONFIG))
        data = None
    return data

def get_val_for_new_key(key, sample_dict, instance_dict):
    ret_val = sample_dict[key]
    return ret_val

def get_val_spl_dict_inst_not_dict(key,sample_dict,instance_dict):
    #ret_val = "Sample value is dict, instance value is not dict"
    ret_val = sample_dict[key]
    return ret_val

def get_val_spl_not_dict_inst_not_dict(key,sample_dict,instance_dict):
    #ret_val = "Sample value is not dict, instance value is dict"
    ret_val = sample_dict[key]
    return ret_val


def convert_conf_sample2instance(sample_dict,instance_dict, deep_path="root"):
    final_dict = {}
    count_changed = 0
    for key,value in sample_dict.items():
        if key not in instance_dict:
            final_dict[key] = get_val_for_new_key(key, sample_dict, instance_dict)
            count_changed = count_changed + 1
            continue
 
        sample_value = value
        instance_value = instance_dict[key]
       
        if (not isinstance(sample_value,dict)) and (not isinstance(instance_value,dict)):
            if (deep_path == "root") and (key == "version") and (sample_value != instance_value):
                final_dict[key] = sample_value
                count_changed = count_changed + 1
            else:
                final_dict[key] = instance_value
            continue

        if (isinstance(sample_value,dict)) and (not isinstance(instance_value,dict)):
            final_dict[key] = get_val_spl_dict_inst_not_dict(key,sample_dict,instance_dict)
            count_changed = count_changed + 1
            continue

        if (not isinstance(sample_value,dict)) and (isinstance(instance_value,dict)):
            final_dict[key] = get_val_spl_not_dict_inst_not_dict(key,sample_dict,instance_dict)
            count_changed = count_changed + 1
            continue
        
        if (isinstance(sample_value,dict)) and (isinstance(instance_value,dict)):
            sub_deep_path = deep_path + '.' + key
            final_dict[key],sub_count_changed = convert_conf_sample2instance(value,instance_dict[key],sub_deep_path)
            count_changed = sub_count_changed +  count_changed
            continue
    return final_dict, count_changed

def override_instance_config(final_dict, count_changed):
    print("Sample config path: %s" % PATH_SAMPLE_CONFIG)
    print("Instance config path: %s" % PATH_INSTANCE_CONFIG)
    if count_changed != 0:
        print("Instance config has %d will be changed" % count_changed)
        #print(yaml.dump(final_dict,Dumper=yaml.Dumper))
        fd = open(PATH_INSTANCE_CONFIG,'w',encoding="utf-8")
        yaml.dump(final_dict, fd)
        fd.close()
        print("Update the instance file ...")
    else:
        #print(yaml.dump(final_dict,Dumper=yaml.Dumper))
        print("Retain the instance file ...")

if __name__ == "__main__":
    sample_dict = obtain_conf_dict(PATH_SAMPLE_CONFIG)
    instance_dict = obtain_conf_dict(PATH_INSTANCE_CONFIG)
    if (sample_dict == None) or (instance_dict == None):
        sys.exit(1)
    final_dict,count_changed = convert_conf_sample2instance(sample_dict,instance_dict)
    override_instance_config(final_dict,count_changed)

