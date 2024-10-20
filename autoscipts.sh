#!/bin/bash

function create_lvm_partition() {
    clear
    echo "==== Tạo Logical Volume (LVM) ===="
    echo "Danh sách các thiết bị lưu trữ:"
    lsblk
    
    # Nhập nhiều phân vùng
    read -p "Nhập tên các thiết bị để tạo Volume Group (VD: sdb1 sdb2): " devices
    
    # Tạo một danh sách đường dẫn đầy đủ của các thiết bị
    full_devices=""
    valid=true
    for device_name in $devices; do
        device="/dev/$device_name"
        if [[ -b $device ]]; then
            full_devices="$full_devices $device"  # Thêm thiết bị hợp lệ vào danh sách
        else
            echo "Thiết bị $device không tồn tại."
            valid=false
            break
        fi
    done
    
    if [ "$valid" = true ]; then
        read -p "Nhập tên cho Volume Group (VG): " vg_name
        read -p "Nhập tên cho Logical Volume (LV): " lv_name
        read -p "Nhập kích thước cho Logical Volume (ví dụ: 10G): " lv_size
        
        # Tạo Physical Volumes từ danh sách các phân vùng
        for device_name in $devices; do
            device="/dev/$device_name"
            pvcreate $device
            sleep 1
        done
        
        echo $full_devices
        # Tạo Volume Group từ nhiều Physical Volumes
        # Kiểm tra xem Volume Group đã tồn tại chưa
        vg_exists=$(vgdisplay $vg_name 2>/dev/null)
        
        if [ -z "$vg_exists" ]; then
            # Nếu Volume Group không tồn tại, tạo mới
            vgcreate $vg_name $full_devices
            echo "Volume Group $vg_name đã được tạo mới."
        else
            # Nếu Volume Group tồn tại, thêm Physical Volume vào Volume Group
            vgextend $vg_name $full_devices
            echo "Các phân vùng đã được thêm vào Volume Group $vg_name."
        fi
        sleep 1
        
        # Tạo Logical Volume với kích thước được chỉ định
        lvcreate -L $lv_size -n $lv_name $vg_name
        sleep 1
        
        # Định dạng Logical Volume với hệ thống tệp ext4
        mkfs.ext4 "/dev/$vg_name/$lv_name"
        echo "Logical Volume đã được tạo thành công."
    else
        echo "Quá trình bị hủy do thiết bị không tồn tại."
    fi
    
    read -p "Nhấn Enter để tiếp tục..."
}

function remove_lvm_partition() {
    clear
    echo "==== Xóa Logical Volume (LVM) ===="
    echo "Danh sách các Logical Volume (LV):"
    lvdisplay
    read -p "Nhập tên Logical Volume (LV) để xóa (VD: my_vg/my_lv): " lv_name
    
    # Kiểm tra xem LV có tồn tại không
    if lvdisplay | grep -q $lv_name; then
        # Lấy tên Volume Group từ Logical Volume
        vg_name=$(lvdisplay $lv_name | grep "VG Name" | awk '{print $3}')
        
        # Xóa Logical Volume
        lvremove -y $lv_name
        echo "Logical Volume $lv_name đã được xóa thành công."
        
        # Xóa các Physical Volumes khỏi Volume Group
        echo "Danh sách các Physical Volume (PV) thuộc Volume Group $vg_name:"
        pvs --noheadings -o pv_name,vg_name | grep $vg_name
        
        # Gỡ bỏ các PV khỏi VG
        read -p "Bạn có muốn xóa tất cả các PV khỏi VG $vg_name không? (y/n): " remove_pv_choice
        if [ "$remove_pv_choice" = "y" ]; then
            for pv in $(pvs --noheadings -o pv_name,vg_name | grep $vg_name | awk '{print $1}'); do
                vgreduce $vg_name $pv
                pvremove -ff $pv
                echo "Physical Volume $pv đã được gỡ bỏ khỏi Volume Group và xóa."
            done
            
            # Xóa Volume Group nếu không còn Physical Volume nào
            vgremove $vg_name
            echo "Volume Group $vg_name đã được xóa."
        fi
    else
        echo "Logical Volume không tồn tại."
    fi
    read -p "Nhấn Enter để tiếp tục..."
}

function editLimitQuota(){
    clear
    read -p "Vui lòng nhập tên phân vùng hoặc volume cần cấu hình quota: " path
    read -p "Đặt tên thư mục cần mount: " directory
    read -p "Nhập tên user cần thiết lập quota: " user
    read -p "Nhập soft limit (KB): " soft_limit
    read -p "Nhập hard limit (KB): " hard_limit
    mkdir $directory
    mount $path $directory
    absolute_path=$(realpath $directory)
    echo "$path $absolute_path ext4 defaults,usrquota,grpquota 0 2" | sudo tee -a /etc/fstab
    mount -o remount $absolute_path
    quotacheck -avug
    setquota -u "$user" "$soft_limit" "$hard_limit" "0" "0" "$absolute_path"
    quotaon -avug
    quota -v -u "$user"
    read -p "Nhấn Enter để tiếp tục..."
}

function removeLimitQuota(){
    clear
    read -p "Nhập tên user cần xóa giới hạn quota: " user
    read -p "Nhập thư mục đã được thiết lập quota: " path
    setquota -u "$user" 0 0 0 0 "$path"
    echo "Giới quota đã được xóa đi"
    quota -v -u "$user"
    read -p "Nhấn Enter để tiếp tục..."
}


while true; do
    clear
    echo "==== Quản lý ổ đĩa ===="
    echo "1. Xem thông tin ổ đĩa"
    echo "2. Tạo mới phân vùng"
    echo "3. Xóa phân vùng"
    echo "4. Quản lý Logical Volume (LVM)"
    echo "5. Kiểm tra tình trạng ổ đĩa"
    echo "6. Danh sách các thiết bị lưu trữ"
    echo "7. Thiết lập giới hạn Quota"
    echo "8. Kiểm tra giới hạn Quota"
    echo "9. Xóa giới hạn Quota"
    echo "10. Thoát"
    read -p "Chọn một tùy chọn (1/2/3/4/5/6/7/8/9/10): " choice
    
    case $choice in
        1)
            echo "Thông tin ổ đĩa:"
            df -h
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        2)
            echo "Danh sách các thiết bị lưu trữ:"
            lsblk
            read -p "Nhập tên thiết bị để tạo phân vùng (ví dụ: sdb): " device_name
            device="/dev/$device_name"
            
            read -p "Nhập số phân vùng (ví dụ: 1 cho sdb1): " partition_number
            partition_path="${device}${partition_number}"
            echo $partition_path
            
            # Kiểm tra xem thiết bị có tồn tại không
            if [[ -b $device ]]; then
                if [[ ! -b $partition_path ]]; then
                    read -p "Nhập kích thước phân vùng (ví dụ: 10G): " partition_size
                    start_position=$(parted $device unit MiB print free | grep 'Free Space' | tail -n 1 | awk '{print $1}')
                    start_position=${start_position%MiB}  # Xóa đơn vị MiB
                    end_position=$(echo "$start_position + ${partition_size%G} * 1024" | bc)
                    echo "Tạo phân vùng từ ${start_position}MiB đến ${end_position}MiB"
                    # Tạo phân vùng mới với kích thước từ 0% đến partition_size
                    parted -s $device mkpart primary ext4 "${start_position}MiB" "${end_position}MiB"
                    # Cập nhật bảng phân vùng
                    partprobe $device
                    sleep 1  # Tạm dừng ngắn để hệ thống cập nhật
                    # Định dạng phân vùng mới
                    mkfs.ext4 $partition_path
                    echo "Phân vùng $partition_path đã được tạo và định dạng thành công."
                    # Hiển thị lại danh sách phân vùng sau khi tạo
                    lsblk
                else
                    echo "Phân vùng $partition_path đã tồn tại!"
                fi
            else
                echo "Thiết bị không tồn tại, hoặc phân vùng đã tồn tại !"
            fi
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        3)
            echo "Danh sách các thiết bị lưu trữ:"
            lsblk
            read -p "Nhập tên thiết bị cần xóa: " partition_name
            read -p "Nhập phân vùng cần xóa (vd: 1 cho sdb1): " num
            partition="/dev/$partition_name"
            
            # Kiểm tra xem phân vùng có tồn tại không
            if [[ -b $partition ]]; then
                umount $partition  # Đảm bảo phân vùng đã được unmount trước khi xóa
                parted -s $partition rm $num
                echo "Phân vùng đã được xóa thành công."
            else
                echo "Phân vùng không tồn tại."
            fi
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        4)
            PS3="Chọn một tùy chọn LVM: "
            options=("Tạo Logical Volume" "Xóa Logical Volume" "Hiển thị danh sách Volume Group" "Hiển thị danh sách Logical Volume" "Quay lại")
            select lvm_option in "${options[@]}"; do
                case $lvm_option in
                    "Tạo Logical Volume")
                        create_lvm_partition
                        break
                    ;;
                    "Xóa Logical Volume")
                        remove_lvm_partition
                        break
                    ;;
                    "Hiển thị danh sách Volume Group")
                        clear
                        vgdisplay
                        
                    ;;
                    "Hiển thị danh sách Logical Volume")
                        clear
                        lvdisplay
                        
                    ;;
                    "Quay lại")
                        break
                    ;;
                    *) echo "Tùy chọn không hợp lệ";;
                esac
            done
        ;;
        5)
            echo "Danh sách các thiết bị lưu trữ:"
            lsblk
            read -p "Nhập tên ổ đĩa để kiểm tra tình trạng (ví dụ: sda): " drive_name
            drive="/dev/$drive_name"
            
            # Kiểm tra xem ổ đĩa có tồn tại không
            if [[ -b $drive ]]; then
                smartctl -H $drive
            else
                echo "Ổ đĩa không tồn tại."
            fi
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        6)
            echo "Danh sách các thiết bị lưu trữ:"
            lsblk
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        7)
            editLimitQuota
        ;;
        8)
            echo "Danh sách giới hạn Quota:"
            repquota -avug
            read -p "Nhấn Enter để tiếp tục..."
        ;;
        9)
            removeLimitQuota
        ;;
        10)
            echo "Kết thúc chương trình."
            exit 0
        ;;
        *)
            echo "Tùy chọn không hợp lệ. Vui lòng chọn lại."
        ;;
    esac
done
