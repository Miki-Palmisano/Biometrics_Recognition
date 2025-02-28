%% clear space
clear all, close all, clc

n_person = 49;
n_iris = 9;

%% Elaboro la matrice degli iridi

% Percorso del dataset
base_path = './casia-iris-converted/';

AIris_matrix = [];

for i = 0:(n_person-5)
    if i < 10
        directory = base_path + "00" + i + "/0";
    elseif i < 100
        directory = base_path + "0" + i + "/0";
    else
        directory = base_path + i + "/0";
    end

    for j = 0:(n_iris-1)
        img_path = directory + j + ".jpg";

        % Estrazione e analisi dell'immagine
        AIris = double(imread(img_path));

        AIris_matrix = [AIris_matrix AIris(:)];

        fprintf("Immagine: " + j + " cartella: " + i + "\n")
    end

end

%% Applico SVD
mean_AIris = mean(AIris_matrix, 2);
AIris_matrix = AIris_matrix - mean_AIris*ones(1,size(AIris_matrix,2));

[U, S, V] = svd(AIris_matrix, "econ");

% trovo l'indice che spiega almeno 90% dell'energia
k = find(cumsum(diag(S).^2)/sum(diag(S).^2) > 0.9, 1);

% calcolo la correllazione tra la matrice e se stessa
corr_matrix = corr(AIris_matrix);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;
%% Visualizzo i primi Eigeniris
% Gli eigeniris sono rappresentazioni della media degli iridi nel dataset, 
% dove ogni colonna di U rappresenta la caratteristica che spiega la 
% varianza maggiore nel dataset. Regioni di colore più chiare catturano 
% direzioni (tratti) che distinguono gli iridi rispetto alla media
%{
numEigenIrisToShow = 9; % Numero di autovettori da visualizzare
figure;
for i = 1:numEigenIrisToShow
    eigenIris = reshape(U(:, i), [100 360]); % Reshape in immagine
    subplot(3, 3, i);
    imshow(eigenIris, []);
    title(['Eigeniris #' num2str(i)]);
end
%}

%% Calcolo precisione
% avviare il contatore del tempo
tic;
TP = 0;                        
FP = 0;

for j=0:(n_person-5)
    if j < 10
        test_path = "./casia-iris-converted/00"+j+"/09.jpg";
    else
        test_path = "./casia-iris-converted/0"+j+"/09.jpg";
    end
    

    AIris_test = double(imread(test_path));
    AIris_test = AIris_test(:) - mean_AIris;
    
    % considero vettori colonna
    AIris_test_projected = U(:,1:k)' * (AIris_test);
    
    % Confronto tramite norma euclidea con tutte le colonne della matrice
    distances = [];

    for i=1: size(AIris_matrix, 2)
        stored_AIris = U(:,1:k)' * AIris_matrix(:,i);
    
        distances = [distances norm(AIris_test_projected - stored_AIris)];
    end
    
    percentage_distances = (1 - distances / max(distances)) * 100;
    [value, indices] = max(percentage_distances);
    
    % Calcolo l'indice della persona, considerando che ogni persona ha 9 immagini
    personIndex = floor((indices) / 9);

    if j == personIndex
        TP = TP + 1;
    else
        FP = FP + 1;
    end

    fprintf("Elaboro "+j+"\n")
end

precision = (TP/(TP+FP)) * 100;

fprintf("Precisione: %d%%\n", uint8(precision))
time=toc;

%% grafico confronto tempo e precisione a seconda della soglia scelta
soglie=[0.99 0.95 0.90 0.85 0.80 0.75 0.7 0.65 0.6 0.55 0.5 0.45];
tempo=[152.18 61.20 26.99 15.23 8.47 6.5 4.76 3.42 1.84 1.2 1.2 1.65];
precisione=[0.67 0.64 0.67 0.62 0.58 0.58 0.47 0.47 0.4 0.31 0.31 0.09];

figure;
hold on;

% Asse sinistro: Tempo di esecuzione
yyaxis left;
plot(soglie, tempo, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'b');
ylabel('Tempo di Esecuzione (s)');

% Asse destro: Precisione
yyaxis right;
plot(soglie, precisione, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'r');
ylabel('Precisione');

xlabel('Percentuale di Energia Spiegata')

% Titolo e legenda
title('Variazione di Tempo e Precisione');
legend({'Tempo di esecuzione', 'Precisione'}, 'Location', 'southwest');

grid on;
hold off;

%% grafico energia
energia=cumsum(diag(S).^2)/sum(diag(S).^2);
hold on;
plot(1:length(energia),energia, 'LineWidth',2,'Color','g')

% Esempio: evidenziare i punti di interesse
punti = [2 3 13 50 124 295]; % Indici dei punti da evidenziare (puoi modificarli)
valori_punti = energia(punti); % Valori corrispondenti

for t = 1 : 6
    % Aggiungi marker sui punti specifici
    plot(punti(t), valori_punti(t), 'bo', 'MarkerFaceColor', 'b'); % Punti con cerchi blu pieni
    text(punti(t), valori_punti(t), sprintf('%.2f%%', valori_punti(t)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

xlabel('Valori Singolari')
ylabel('Energia Spiegata')

hold off;
%% proietto la matrice nello spazio ridotto
AIris_new=[];
for i=1: size(AIris_matrix, 2)
    AIris_new = [AIris_new (U(:,1:k)' * AIris_matrix(:,i))];
end

% ricalcolo la correllazione tra la matrice e se stessa
corr_matrix = corr(AIris_new);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;
%% Prendo un immagine dal set di test, confronto singolo campione
%{
test_path = './casia-iris-converted/048/09.jpg';

AIris_test = double(imread(test_path));
AIris_test = AIris_test(:) - mean_AIris;
% considero vettori colonna
AIris_test_projected = U' * AIris_test;


% Confronto tramite norma euclidea con tutte le colonne della matrice
distances = [];

for i=1: size(AIris_matrix,2)
    stored_AIris = U' * AIris_matrix(:,i);

    distances = [distances norm(AIris_test_projected - stored_AIris)];
    fprintf("Elaboro "+i+"\n")
end

percentage_distances = (1 - distances / max(distances)) * 100;
[value, indices] = max(percentage_distances);

% Calcolo l'indice della persona, considerando che ogni persona ha 8 immagini
personIndex = floor((indices) / 9);

fprintf("l'Iride più simile a quello di test è %d al %d%%\n", personIndex, uint8(value))

plot(percentage_distances)
%}

%% creo matrice con persone escluse dal dataset

AIris_test_matrix = [];
for i=45:49
    test_path = "./casia-iris-converted/0"+i+"/09.jpg";

    AIris_test = double(imread(test_path));
    AIris_test = AIris_test(:) - mean_AIris;
    AIris_test = U(:,1:k)' * AIris_test;
    
    AIris_test_matrix = [AIris_test_matrix AIris_test];
    
end

% ricalcolo matrice di correlazione
corr_matrix = corr(AIris_new,AIris_test_matrix);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;