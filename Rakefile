require 'erb'
require 'uri'
require 'net/http'
require 'net/https'

STDOUT.sync = true

# This rake file is designed to be rull on the cloudbox or a  ubuntu 12.0.4 VM
RUNDIR = File.dirname(__FILE__)
BASE_ISO_FILE  = "ubuntu-12.04-server-amd64.iso"
BASE_ISO_URL   = "http://faro/ISO/Ubuntu/#{BASE_ISO_FILE}"

NEW_ISO_NAME   = "cloudbox"
NEW_ISO_FILE   = "#{NEW_ISO_NAME}.iso"
NEW_ISO_DEV    = "/dev/sdb1"

# Download PE
PEVERSION = '2.5.3'
PE_RELEASE_URL = "https://pm.puppetlabs.com/puppet-enterprise/#{PEVERSION}"
PE_DEV_URL = "http://pluto.puppetlabs.lan/ci-ready"
PE_URL = PE_RELEASE_URL # Set the place you want to get PE from
PE_INSTALL_SUFFIX = '-ubuntu-12.04-amd64' 

STUDENT_VM_NAME  = 'centos-5.7-pe-2.5.2.img'
STUDENT_VM_URL   = "http://faro/ISO/KVM/#{STUDENT_VM_NAME}"
SAVEDIR = ENV['HOME'] + "/Desktop/#{NEW_ISO_NAME}-isobuild"

task :default do
      sh %{rake -T}
end

desc "Build and populate iso directory"
task :init do
  # Make our work dirs
  [SAVEDIR].each do |dir|
    unless File.directory?(dir)
      cputs "Making directory #{dir}"
      FileUtils.mkdir(dir)
    end
  end
  
  # Download the iso
  unless File.exist?("#{SAVEDIR}/#{BASE_ISO_FILE}")
    # Prompt for the base ISO URL
    cprint "Please specify iso url [#{BASE_ISO_URL}]: "
    iso_uri = STDIN.gets.chomp.rstrip
    iso_uri = BASE_ISO_URL if iso_uri.empty?
    cputs "Downloading ISO..."
    download iso_uri, "#{SAVEDIR}/#{BASE_ISO_FILE}"
  end

  # Mount the iso
  unless File.exist?("#{SAVEDIR}/iso_mount")
    cputs "Mounting ISO..."
    # Create the iso mount point
    FileUtils.mkdir("#{SAVEDIR}/iso_mount")
    %x{mount -o loop "#{SAVEDIR}/#{BASE_ISO_FILE}" "#{SAVEDIR}/iso_mount"}
  end

  # Copy the iso files
  unless File.exist?("#{SAVEDIR}/ubuntu_files")
    cputs "Creating working directory"
    # Create editable copy
    FileUtils.mkdir("#{SAVEDIR}/ubuntu_files")
  end
  cputs "Copying iso files to working directory..."
  %x{rsync -a "#{SAVEDIR}/iso_mount/." "#{SAVEDIR}/ubuntu_files"}

  # Grab the copy of PE for the hypervisor
  unless File.exist?("#{RUNDIR}/preseed/cloudbox/puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}.tar.gz")
    cputs "Downloading PE #{PEVERSION} for hypervisor..."
    download "#{PE_URL}/puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}.tar.gz", "#{RUNDIR}/preseed/cloudbox/puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}.tar.gz"
  end

  # Extract the installer
  unless File.exist?("#{RUNDIR}/preseed/cloudbox/puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}")
    FileUtils.cd("#{RUNDIR}/preseed/cloudbox/", :verbose => true)
    %x{ tar -xzf "puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}.tar.gz" }
    FileUtils.rm("puppet-enterprise-#{PEVERSION}#{PE_INSTALL_SUFFIX}.tar.gz")
  end

  unless File.exist?("#{RUNDIR}/preseed/cloudbox/#{STUDENT_VM_NAME}")
    cputs "Downloading student VM..."
    download "#{STUDENT_VM_URL}","#{RUNDIR}/preseed/cloudbox/#{STUDENT_VM_NAME}"
  end
  # Add our customizations to the iso
  cputs "Configuring preseeding..."
  FileUtils.cp_r("#{RUNDIR}/preseed/.","#{SAVEDIR}/ubuntu_files/preseed/")

  cputs "Configuring automatic installation..."
  # Configure automatic installation
  FileUtils.cp_r("#{RUNDIR}/isolinux/.","#{SAVEDIR}/ubuntu_files/isolinux/")

  # fix any perm/owner issues
  FileUtils.chmod(444,"#{SAVEDIR}/ubuntu_files/isolinux/txt.cfg")
  FileUtils.chown('root','root',"#{SAVEDIR}/ubuntu_files/isolinux/txt.cfg")

  # Fix any perm/owner issues
  FileUtils.chmod(555,"#{SAVEDIR}/ubuntu_files/isolinux/isolinux.cfg")
  FileUtils.chown('root','root',"#{SAVEDIR}/ubuntu_files/isolinux/isolinux.cfg")

  # Build the new iso
  if File.exists?("#{SAVEDIR}/#{NEW_ISO_FILE}")
    cputs "Removing previous iso..."
    FileUtils.rm("#{SAVEDIR}/#{NEW_ISO_FILE}")
  end

  # Make sure we have syslinux for mbr binary
  if File.exists?('/usr/lib/syslinux/isohdpfx.bin')
    cputs "Installing syslinux"
    %x{apt-get install syslinux -y}
  end
  # Check to make sure xorriso is installed
  xorriso = %x{which xorriso}.chomp
  unless File.executable?(xorriso)
    cputs "Installing xorriso..."
    %x{apt-get install xorriso -y}
  end

  # Build our new iso with MBR record
  cputs "Rebuilding iso from modfied directory..."
  FileUtils.cd("#{SAVEDIR}/ubuntu_files", :verbose => true)
  %x{xorriso \
         -as mkisofs \
         -r \
         -V "#{NEW_ISO_NAME}" \
         -J \
         -l \
         -b isolinux/isolinux.bin \
         -c isolinux/boot.cat \
         -no-emul-boot \
         -isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
         -boot-load-size 4 \
         -boot-info-table -o "#{SAVEDIR}/#{NEW_ISO_FILE}" . }

  STDOUT.sync = true
  STDOUT.flush
end

desc "Copy iso to thumb drive"
task :thumb do
  # Copy our iso to our thumb drive
  cputs "Copying iso to thumb drive..."
  %x{dd if="#{SAVEDIR}/#{NEW_ISO_FILE}" of="#{NEW_ISO_DEV}" bs=1M} 
end

desc "Remove the temp directories"
task :clean do
  FileUtils.rm_rf(SAVEDIR)
end

def download(url,path)
  u = URI.parse(url)
  net = Net::HTTP.new(u.host, u.port)
  case u.scheme
  when "http"
    net.use_ssl = false
  when "https"
    net.use_ssl = true
    net.verify_mode = OpenSSL::SSL::VERIFY_NONE
  else
    raise "Link #{url} is not HTTP(S)"
  end
  net.start do |http|
    resp = http.get(u.path)
    open(path, "wb") do |file|
      file.write(resp.body)
    end
  end
end

def cputs(string)
  puts "\033[1m#{string}\033[0m"
end

def cprint(string)
  print "\033[1m#{string}\033[0m"
end

# vim: set sw=2 sts=2 et tw=80 :
