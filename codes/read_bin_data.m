% This function gets the file name and generate the data structure containg
% the raw signal and descriptions


function [data_out] = read_bin_data(filename)

fid = fopen(filename);
read = 1;
ORN = [];
EEG = [];
ENV = [];
TS = [];
while read
    [pid,n] = fread(fid,1,'*ubit8');
    cnt = fread(fid,1,'*ubit8');    % Counter of the package
    payload = fread(fid,1,'uint16');% Number of bytes in the package
    timestamp = fread(fid,1,'uint32');% Timestamp of the package
    if n==0
        break;
    end
    
    if pid == 13  % Orientation package
        idx = length(ORN)+1;
        ORN(idx).cnt = cnt;
        ORN(idx).timestamp = timestamp;
        ORN(idx).data = fread(fid,(payload-8)/2,'int16');
    elseif pid == 19 % Environment package
        idx = length(ENV)+1;
        ENV(idx).cnt= cnt;
        ENV(idx).timestamp = timestamp;
        ENV(idx).temperature = fread(fid,1,'*bit8');
        ENV(idx).light = fread(fid,1,'uint16');
        ENV(idx).battery = fread(fid,1,'uint16');
    elseif (pid == 144)||(pid==146)||(pid==30) % EEG package with status info
        idx = length(EEG)+1;
        EEG(idx).cnt= cnt;
        EEG(idx).timestamp = timestamp;
        [temp,n] = fread(fid,(payload-8)/3,'*bit24');
        temp = int32(temp/32);
        if n< ((payload-8)/3) %check if the package terminates in between
            break;
        end
        if pid ==144  % Specify the number of channel and reference voltage
            nChan = 4;
            vref = 2.4;
        elseif pid == 146
            nChan = 8;
            vref = 2.4;
        else    
            nChan = 8;
            vref = 4.5;
        end
        temp = reshape(temp,[nChan+1,33]);
        EEG(idx).data = double(temp(2:end,:))* vref / ( 2^23 - 1 ) * 6; % Calculate the real voltage value
        EEG(idx).status = temp(1,:);    %save the status of data points
    elseif (pid==62)    %EEG package without status for data points
        EEG(idx).timestamp = timestamp;
        [temp,n] = fread(fid,(payload-8)/3,'*bit24');
        temp = int32(temp/32);
        if n< ((payload-8)/3)
            break;
        end
        temp = reshape(temp,[nChan,33]);
        EEG(idx).data = double(temp)* vref / ( 2^23 - 1 ) * 6;
    elseif pid ==27 % Timestamp package
        idx = length(TS)+1;
        TS(idx).cnt= cnt;
        TS(idx).timestamp = timestamp;
        TS(idx).data = fread(fid,(payload-8)/4,'uint32');
    else
        disp(pid); % Print if there is any other ID
        temp = fread(fid,payload-8,'*bit8'); % Read the payload
    end
    [fletcher, n] = fread(fid,4,'*ubit8');
    % Check the consistency of the Fletcher
    if n<4
        break;
    elseif((pid~=27)&&(fletcher(4) ~= 222)) || ((pid==27)&&(fletcher(4)~=255))
        ME = MException('Validity Error', ...
        'The Fletcher is not consistent',str);
        throw(ME)
    end
end

% Check if the last entry in the structures is empty. (If the data stream
% ends in the middle of a package, we throw away that package)
if isempty(EEG(end).data)
    EEG(end)=[];
end
if isempty(ORN(end).data)
    ORN(end)=[];
end
if isempty(ENV(end).battery)
    ENV(end)=[];
end
if isempty(TS(end).data)
    TS(end)=[];
end

data_out.EEG = EEG;
data_out.ENV = ENV;
data_out.ORN = ORN;
data_out.TS = TS;

save('data_out');
end
