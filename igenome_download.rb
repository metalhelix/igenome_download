#!/usr/bin/env ruby

require 'json'
require 'net/ftp'

BASE_URL = "ussd-ftp.illumina.com"
USERNAME = "igenome"
PASSWORD = "G3nom3s4u"

URL = "ftp://#{USERNAME}:#{PASSWORD}@#{BASE_URL}"

MTIME_FILE = "igenome_downloads.json"

c_elegans = ["Caenorhabditis_elegans/UCSC/ce6/Caenorhabditis_elegans_UCSC_ce6.tar.gz"]

homo_sapien = ["Homo_sapiens/UCSC/hg19/Homo_sapiens_UCSC_hg19.tar.gz",
         "Homo_sapiens/UCSC/hg18/Homo_sapiens_UCSC_hg18.tar.gz",
         "Homo_sapiens/NCBI/build37.2/Homo_sapiens_NCBI_build37.2.tar.gz",
         "Homo_sapiens/NCBI/build36.3/Homo_sapiens_NCBI_build36.3.tar.gz"]

mus_musc = ["Mus_musculus/NCBI/build37.2/Mus_musculus_NCBI_build37.2.tar.gz",
            "Mus_musculus/NCBI/build37.1/Mus_musculus_NCBI_build37.1.tar.gz",
            "Mus_musculus/UCSC/mm10/Mus_musculus_UCSC_mm10.tar.gz",
            "Mus_musculus/UCSC/mm9/Mus_musculus_UCSC_mm9.tar.gz"]

dro_mel = ["Drosophila_melanogaster/UCSC/dm3/Drosophila_melanogaster_UCSC_dm3.tar.gz",
           "Drosophila_melanogaster/NCBI/build5.3/Drosophila_melanogaster_NCBI_build5.3.tar.gz",
           "Drosophila_melanogaster/NCBI/build5/Drosophila_melanogaster_NCBI_build5.tar.gz",
           "Drosophila_melanogaster/Ensembl/BDGP5/Drosophila_melanogaster_Ensembl_BDGP5.tar.gz",
           "Drosophila_melanogaster/Ensembl/BDGP5.25/Drosophila_melanogaster_Ensembl_BDGP5.25.tar.gz"]

phix = ["PhiX/Illumina/RTA/PhiX_Illumina_RTA.tar.gz",
        "PhiX/NCBI/1993-04-28/PhiX_NCBI_1993-04-28.tar.gz"]

sac_cer = ["Saccharomyces_cerevisiae/UCSC/sacCer3/Saccharomyces_cerevisiae_UCSC_sacCer3.tar.gz",
           "Saccharomyces_cerevisiae/UCSC/sacCer2/Saccharomyces_cerevisiae_UCSC_sacCer2.tar.gz",
           "Saccharomyces_cerevisiae/NCBI/build3.1/Saccharomyces_cerevisiae_NCBI_build3.1.tar.gz",
           "Saccharomyces_cerevisiae/NCBI/build2.1/Saccharomyces_cerevisiae_NCBI_build2.1.tar.gz",
           "Saccharomyces_cerevisiae/Ensembl/EF4/Saccharomyces_cerevisiae_Ensembl_EF4.tar.gz",
           "Saccharomyces_cerevisiae/Ensembl/EF3/Saccharomyces_cerevisiae_Ensembl_EF3.tar.gz"]

pombe = ["Schizosaccharomyces_pombe/Ensembl/EF2/Schizosaccharomyces_pombe_Ensembl_EF2.tar.gz",
         "Schizosaccharomyces_pombe/Ensembl/EF1/Schizosaccharomyces_pombe_Ensembl_EF1.tar.gz"]

files = [c_elegans, homo_sapien, mus_musc, dro_mel, phix, sac_cer, pombe].flatten

def read_mtimes
  mtimes = {}
  if File.exists?(MTIME_FILE)
    mtimes = JSON.parse(File.open(MTIME_FILE, 'r').read)
  end
  mtimes
end

def write_mtimes mtimes
  File.open(MTIME_FILE, 'w') do |file|
    file.puts JSON.pretty_generate(JSON.parse(mtimes.to_json))
  end
end

def execute command
  puts command
  system(command)
end

def is_newer? new_mtime, old_mtime
  new_mtime.to_s.chomp.strip. != old_mtime.to_s.chomp.strip
end

def get_current_mtime file
  mtime = nil
  Net::FTP.open(BASE_URL, USERNAME, PASSWORD) do |ftp|
    mtime = ftp.mtime(file)
  end
  mtime
end

def download file
  command = "wget #{URL}/#{file}"
  execute(command)
end

def extract file
  basename = File.basename(file)

  command = "tar xvzf #{basename}"
  execute(command)
end

def remove_old file
  dirname = File.dirname(file)
  if File.exists?(dirname)
    puts "removing #{dirname}"
    command = "rm -rf #{dirname}"
    execute(command)
  end
end

def remove(file)
  basename = File.basename(file)
  command = "rm -rf #{basename}"
  execute(command)
end

mtimes = read_mtimes

puts files.inspect

files.each do |file|
  new_mtime = get_current_mtime(file)
  needs_download = false
  if mtimes[file]
    if(is_newer?(new_mtime, mtimes[file]))
       needs_download = true
    else
      puts "#{file} already current"
    end
  else
    needs_download = true
  end

  if needs_download
    puts "Downloading #{file}"
    mtimes[file] = new_mtime
    download(file)
    remove_old(file)
    extract(file)
    remove(file)
  end
end

write_mtimes(mtimes)
