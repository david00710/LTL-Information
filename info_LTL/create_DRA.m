function R=create_DRA(filename,N_p,debug)

if nargin<3
    debug=false;
end

R.N_p=N_p;

fid=fopen(filename,'r');
if fid==-1
    error('%s cannot be opened', filename);            
end
tline = fgetl(fid);
while ischar(tline)
    if debug
        disp(tline)
    end
    if strfind(tline, 'States: ')
        k=strfind(tline, 'States: ')+length('States: ');
        state_no=str2double(tline(k:end));
        fprintf('Initializing parsing, total no. of states: %i\n', state_no);
        R.state_no=state_no;
        R.trans=zeros(R.state_no,2^R.N_p);
    end
    
    if strfind(tline, 'Acceptance-Pairs: ')
        k=strfind(tline, 'Acceptance-Pairs: ')+length('Acceptance-Pairs: ');
        R.pairs=str2double(tline(k:end));
        for ii=1:R.pairs
            R.K{ii}=[];
            R.L{ii}=[];
        end
        fprintf('The number of acceptance pairs: %i\n',R.pairs);
    end
    
    if strfind(tline, 'Start: ')
        k=strfind(tline, 'Start: ')+length('Start: ');
        R.S0=str2double(tline(k:end))+1;
        fprintf('Initial state: %i\n',R.S0);
    end
    
    if strfind(tline, 'AP: ')
        fprintf('The AP order: %s\n',tline);
        [token, str] = strtok(tline,  ' "');
        if ~strcmp(token, 'AP:')
            error ('parsing error');
        end
        [token, str] = strtok(str,  ' "');
        R.APs=cell(1, str2double(token));
        for ii=1:length(R.APs)
            if isempty(str)
                error('parsing error');
            end
            [token, str] = strtok(str,  ' "');
            R.APs{ii} = token;
        end
        % disp('Note that order is little Endian! (So need to assign # backwards)');
    end
    
    if strfind(tline, '---')
        disp('Starting Parsing states');
        
        tline = fgetl(fid);
        newState=false;
        
        while ischar(tline)
            if strfind(tline, 'State: ')
                % New state
                k=strfind(tline, 'State: ')+length('State: ');
                state=str2double(tline(k:end))+1;
                if debug
                    fprintf('Current State: %i\n',state);
                end
                
                % Extract Acc-data
                tline = fgetl(fid);
                if ~strfind(tline, 'Acc-Sig:')
                    error('parsing error, missing Acc-Sig: line');
                end
                if strcmp(tline,'Acc-Sig:')
                    if debug
                        disp('Current state not L or K');
                    end
                elseif ~isempty(strfind(tline, 'Acc-Sig: +')) || ~isempty(strfind(tline, 'Acc-Sig: -'))
                    pairstr = tline(length('Acc-Sig: '):end);
                    acctok = strread(pairstr, '%s', 'delimiter', ' ');
                    for ind = 1:length(acctok)
                        if ~isempty(acctok{ind})
                            if ~isempty(strfind(acctok{ind}, '+'))
                                pair = str2double(acctok{ind}(2:end)) + 1;
                                R.K{pair}=[R.K{pair}, state];
                                if debug
                                    fprintf('Current state is new K state: %i for pair %i\n',state,pair);
                                end
                            elseif ~isempty(strfind(acctok{ind}, '-'))
                                pair = str2double(acctok{ind}(2:end)) + 1;
                                R.L{pair}=[R.L{pair}, state];
                                if debug
                                    fprintf('Current state is new L state: %i for pair %i\n',state,pair);
                                end
                            else
                                error('For line %s, pairstr %s error', tline, pairstr);
                            end
                        end
                    end
                else
                    error('Parsing error, Acc-Sig not expected');
                end
                
                % Extract Transition-data
                % expect 2^R.N_p lines                
                for input=0:(2^R.N_p-1)
                    tline=fgetl(fid);
                    next_state=str2double(tline)+1;
                    % For legacy definition of empty set=2^N_p
                    if input==0
                        R.trans(state,2^R.N_p)=next_state;
                    else
                        R.trans(state,input)=next_state;
                    end
                end
                tline = fgetl(fid);
            else
                error('Parsing unexpected error');
            end                
        end
        disp('Parsing complete');
        break
    end
    tline = fgetl(fid);
end
fclose(fid);