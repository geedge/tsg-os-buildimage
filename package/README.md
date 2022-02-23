# TSG-9140 内核升级注意事项
## 除了需要更新内核RPM外还需要特别注意的是：根据升级后的内核重新编译i40E以及iavf驱动的rpm,具体编译方法在ansible/roles/i40e-drive路径下的Readme文件