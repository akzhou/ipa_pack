#!/bin/bash

#-------------------------------------------------------------------------------
#                           多渠道打包工具 make by AK                            #
#-------------------------------------------------------------------------------
#（1），project－Info.plist: 增加渠道字段,可用于友盟，百度等统计平台
#					<key>Channel</key>
#					<string>AppStore</string>
#
#（2），channel_array:渠道字段数组，遇到用空格
#
#（3），本文件放在工程根目录,终端下运行 ./ipa_pack.sh,编译后的ipa文件./build/ipa中。
#-------------------------------------------------------------------------------

# Channel Array  
channel_array=(91 TuZi Tongbu KuaiYong PP TaiPingYang)

function loadPath()
{
	#项目名字
	project_name=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
	#项目根路径
	project_dir_path=$(pwd)
	#build路径
	build_dir_path=${project_dir_path}/build
	#.infoplist
	project_info_plist_path=${project_dir_path}/${project_name}/${project_name}-Info.plist
	#Release-iphoneos路径
	release_dir_path=${build_dir_path}/Release-iphoneos
	#.app
	app_path=${release_dir_path}/${project_name}.app
	#ipa存放路径
	ipa_dir_path=${build_dir_path}/ipa
	#log日志文件路径
	log_path=${build_dir_path}/log

	#保存Channel初始值,改动后写回.infoplist
	orgin_channel=$(/usr/libexec/PlistBuddy -c "print Channel" ${project_info_plist_path})
	#版本号
	version=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${project_info_plist_path})

	#删除
	if [ -d ${build_dir_path} ];then
		rm -rf ${build_dir_path}
	fi
	mkdir -p ${ipa_dir_path}	
}

function pack()
{
	#shell读取配置文件写到.infoplist的Channel字段
	#conf_path=${project_dir_path}/channel.conf
	#for channel_name in $(cat channel.conf)
	for channel_name in ${channel_array[@]}
	do
		/usr/libexec/PlistBuddy -c "Set :Channel ${channel_name}" ${project_info_plist_path}
		ipa_path=${ipa_dir_path}/${project_name}_${version}_${channel_name}.ipa
	
		#clean build 
		/usr/bin/xcodebuild  clean

		#build  如果xcode没有配置Code Sign Identity   xcodebuild CODE_SIGN_IDENTITY="iPhone Developer: xxxxxxxx"    或者   iPhone Distribution: xxxxxxxxxx
		/usr/bin/xcodebuild
	
		#xcrun pack ipa    xcrun  -sdk iphoneos PackageApplication  -v ${app_path} -o ${ipa_path} --sign "iPhone Developer: xxxxxxxx"
		/usr/bin/xcrun  -sdk iphoneos PackageApplication  -v ${app_path} -o ${ipa_path}
	done

	/usr/libexec/PlistBuddy -c "Set :Channel ${orgin_channel}" ${project_info_plist_path}
	
}

# 开始时间
start_time=$(date +%s)

#加载路径
loadPath
#打包
pack | tee -a ${log_path}

#结束时间
end_time=$(date +%s)

err=$(grep -n -i error: ${log_path})
if [ -z ${err} ];then
	echo "Complete! Past $((end_time-start_time)) seconds."
else
	echo -e "${err}"
fi

exit