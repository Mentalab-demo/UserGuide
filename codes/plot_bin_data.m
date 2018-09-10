
% Reading the binary file and ploting the signal

filename = 'DATA074.BIN';  % change as per the filename
data = read_bin_data(filename);
EEG_pack = data.EEG;
sig = zeros(4,0);% zeros(4,length(EEG_pack)*size(EEG_pack(1).data,2));

for i=1:length(EEG_pack)
    sig = cat(2,sig,EEG_pack(i).data);
end

figure;
plot(sig(1,:))
hold on
plot(sig(2,:))
plot(sig(3,:))
plot(sig(4,:))
legend('1','2','3','4')
hold off

