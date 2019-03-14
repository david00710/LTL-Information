function info=info_LTL(formula, N_p)
% Inputs:
% formula = 'fo'  Change this to your formula of choice
% N_p  number of predicates
% Outputs:
% info  information gain of the LTL formula
% Zhe Xu UT Austin 03/10/2019
              
if exist(['./' formula '.ltl'], 'file')
    if isunix
        dos(['/Users/xuz/Dropbox/austin/recent/info_LTL/bin/ltl2dstar --ltl2nba=spin:./bin/ltl2ba --output=automaton ./' formula '.ltl ./' formula '.out']);
    elseif ispc
        dos(['bin/ltl2dstar.exe --ltl2nba=spin:./bin/ltl2ba.exe --output=automaton ./' formula '.ltl ./' formula '.out']);
    else
        error('Unknown or unsupported operating system....');
    end
    
    if exist(['./' formula '.out'], 'file')
        R=create_DRA(['./' formula '.out'],N_p);
    else
        error('Cannot create DRA output with ltl2dstar, possible cause: input file does not exist or ltl2dstar binary does not exist');
    end
else
    error('Input LTL formula not found');
end

z = zeros(R.state_no,1);
for i=1:length(R.K)
    z(R.K{i}) = 1;
end

p=1/N_p;

N=10;

Az = zeros(R.state_no,R.state_no);

nl=size(R.trans,2);

Rz(:,1) = R.trans(:,end);
Rz(:,2:nl) = R.trans(:,1:end-1); 

for i=1:size(Rz,1)
    for j=1:size(Rz,2)
        b=de2bi(j-1);
        if length(b)<length(de2bi(size(Rz,2)))
            b=[b zeros(1,length(de2bi(size(Rz,2)))-length(b))];
        end
        a=Rz(i,j);
        c=1;
        for k=1:N_p
            c = c*(p*b(k)+(1-p)*(1-b(k)));            
        end
        Az(i,a) = Az(i,a)+c;
    end
end

for j=1:N
    z =  Az*z;
end

gamma = z(R.S0);

info = -log(gamma)/N;

end




