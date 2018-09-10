% This function gets a binary file and
% convert it to csv file saved in the current directory.


[file,path] = uigetfile('*.BIN');
dataPackage = read_bin_data(strcat(path,file));

%% Data package concatenation
nChan = size(dataPackage.EEG(1).data,1);
sig = zeros(nChan,0);
status = zeros(1,0);
eegTimeStamp = zeros(1,0);
for i=1:length(dataPackage.EEG)
    sig = cat(2,sig,dataPackage.EEG(i).data);
    status = cat(2, status, dataPackage.EEG(i).status);
    eegTimeStamp = cat(2,eegTimeStamp,...
        repmat(dataPackage.EEG(i).timestamp,1,size(dataPackage.EEG(i).status,2)));
end

gyroSig = zeros(length(dataPackage.ORN(1).data),0);
gyroTimeStamp = zeros(1,0);
for i=1:length(dataPackage.ORN)
    gyroSig = cat(2,gyroSig,dataPackage.ORN(i).data);
    gyroTimeStamp = cat(2, gyroTimeStamp, dataPackage.ORN(i).timestamp);
end


%% Writing the header
csvFileName_eeg = strcat(file(1:end-4),'_EEG.csv');
csvFileName_gyro = strcat(file(1:end-4),'_gyro.csv');
fid_eeg = fopen(csvFileName_eeg,'w'); 
fid_gyro = fopen(csvFileName_gyro,'w');

fprintf(fid_eeg,'%s, ','TimeStamp');
for i=1:nChan
    fprintf(fid_eeg,'%s, ',strcat('ch',int2str(i)));
end
fprintf(fid_eeg,'%s\n','Status');

fprintf(fid_eeg,'%s, ','hh:mm:ss');
for i=1:nChan
    fprintf(fid_eeg,'%s, ','mV');
end
fprintf(fid_eeg,'%s\n','(?)');

fprintf(fid_gyro,'%s\n','TimeStamp, ax, ay, az, gx, gy, gz, mx, my, mz');
fprintf(fid_gyro,'%s \n, ','hh:mm:ss, mg/LSB, mg/LSB, mg/LSB, mdps/LSB, mdps/LSB, mdps/LSB, mgauss/LSB, mgauss/LSB, mgauss/LSB');

%% Writing the data into csv file
dlmwrite(csvFileName_eeg,cat(2,double(eegTimeStamp'),sig',double(status')),'-append');
dlmwrite(csvFileName_gyro, cat(2,double(gyroTimeStamp'),gyroSig'),'-append');

fclose(fid_eeg);
fclose(fid_gyro);


