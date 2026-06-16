function DataExtract = readCFSfile(file)
% Made by Fabien. I am not responsible if it dones not work for your
% application :)

% Input : file. Must be the path\file name of the file you want to convert
% from CFS to matlab
% Output : DataExtract. Structure that contains as many fields as there are
% channels in the CFS file you want to convert. The length of the data may
% not be the same in each field because each variable may not have the same
% frequency sampling.

READ=0;
[fhandle]=matcfs64c('cfsOpenFile',file,READ,0); % read only

[time,date,comment]=matcfs64c('cfsGetGenInfo',fhandle);
[channels,fileVars,DSVars,dataSections]=matcfs64c('cfsGetFileInfo',fhandle);

DataExtract.Acquisition_time = time ;
DataExtract.Acquisition_date = date ;
DataExtract.comment = comment ;

if dataSections > 1
    dsVec=1:dataSections;
else
    dsVec=1;
end

for j=1:channels
    [channelName,yUnits,xUnits,dataType,dataKind,spacing,other]=matcfs64c('cfsGetFileChan',fhandle,j-1);
    channelName =  [ strrep(channelName,' ','') '_' num2str(j)] ;
    for i=1:length(dsVec)
       [startOffset,points,yScale,yOffset,xScale,xOffset]=matcfs64c('cfsGetDSChan',fhandle,j-1,dsVec(i));

        if startsWith(channelName,"ADC0") && i==1
            stim_offset=xOffset;                                            % to check potential offset with EMG
        end
        
        if i==1
            DataExtract.(channelName).dat = [] ;
            DataExtract.(channelName).FreqS = 1/xScale ;
        end
         
        if points > 0
            startPt=0;
            [data]=matcfs64c('cfsGetChanData',fhandle,j-1,dsVec(i),startPt,points,dataType);
            data=(data*yScale)+yOffset;

            if startsWith(channelName,"EMG")                                % x offset correction
                nb_frm_offset=round((stim_offset-xOffset)/xScale);
                if nb_frm_offset~=0
                    frm_offset=zeros(abs(nb_frm_offset),1);
                    if nb_frm_offset<0
                        data=[frm_offset ; data];
                    else
                        data=[data ; frm_offset];
                    end
                end
            end

            DataExtract.(channelName).dat = [ DataExtract.(channelName).dat ; data ] ;
        end
    end
end
ret=matcfs64c('cfsCloseFile',fhandle); % close the file