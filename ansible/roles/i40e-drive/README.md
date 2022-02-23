# i40e/iavf驱动编译方法

## 源码下载地址：
* **i40e:**https://www.intel.com/content/www/us/en/download/18026/intel-network-adapter-driver-for-pcie-40-gigabit-ethernet-network-connections-under-linux.html
* **iavf:**https://www.intel.cn/content/www/cn/zh/download/18159/intel-network-adapter-linux-virtual-function-driver-for-intel-ethernet-controller-700-and-e810-series.html
## 编译环境搭建：
* 编译环境的内核需和目标主机内核版本相同
* 安装编译软件：
    * yum install centos-release-scl -y
    * yum install devtoolset-8 -y
* 进入编译shell：
    * scl enable devtoolset-8 bash
* 编译i40e：
    * rpmbuild -tb i40e-2.17.15.tar.gz
    * 编译后的安装包路径：
        * rpmbuild/RPMS/x86_64/i40e-xxx.x86_64.rpm
* 编译iavf：
    *  rpmbuild -tb iavf-4.3.19.tar.gz
    *  编译后的安装包路径：
        *  rpmbuild/RPMS/x86_64/auxiliary-xxx.x86_64.rpm
        *  rpmbuild/RPMS/x86_64/iavf-xxx.x86_64.rp