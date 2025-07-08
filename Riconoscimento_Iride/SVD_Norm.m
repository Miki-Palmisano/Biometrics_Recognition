%% clear space
clear all, close all, clc

n_person = 45;
n_iris = 6;
base_path = "path";
%% Elaboro la matrice degli iridi

AIris_matrix = [];

for i = 1:n_person

    for j = 1:(n_iris-1)
        img_path = directory + j + ".jpg";

        AIris = double(imread(img_path));

        AIris_matrix = [AIris_matrix AIris(:)];

        fprintf("Immagine: " + j + " cartella: " + i + "\n")
    end
end

%% Centro le colonne e proietto nel nuovo spazio
% centro la matrice
mean_AIris = mean(AIris_matrix,2);
AIris_matrix = AIris_matrix - (mean_AIris * ones(1,size(AIris_matrix,2)));

[U, S, V] = svd(AIris_matrix, "econ");

% trovo il numero di valori singolari che spiegano l'80% dell'energia
k = find(cumsum(diag(S).^2) / sum(diag(S).^2) > 0.8, 1);

% calcolo la correlazione tra la matrice e se stessa
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
% funzione per il calcolo del tempo
tic;
TP = 0;
FP = 0;

for j=1:n_person

    AIris_test = double(imread(test_path));

    %AIris_test = (AIris_test - mean(AIris_test(:))) / std(AIris_test(:));
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
    
    % Calcolo l'indice della persona, considerando che ogni persona ha 5 immagini
    personIndex = ceil(indices/5); %arrotondo sempre all'intero maggiore

    if j == personIndex
        TP = TP + 1;
    else
        FP = FP + 1;
    end

    fprintf("Elaboro "+j+"\n")
end

precision = uint8((TP/(TP+FP)) * 100);

fprintf("Precisione: %d%%\n", precision)
time=toc;

%% grafico confronto tempo e precisione a seconda della soglia scelta
soglie=[1 0.99 0.95 0.90 0.85 0.80 0.75 0.70 0.65 0.60 0.55 0.50 0.45 0.40 0.35];
precisione=[0.96 0.93 0.87 0.87 0.87 0.87 0.78 0.76 0.62 0.53 0.44 0.42 0.16 0.16 0.07];
tempo=[60.11 51.80 36.03 22.41 14.54 9.12 6.17 4.55 3.53 2.85 1.88 1 0.76 0.76 0.64];

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

%% grafico energia spiegata
figure;
energia = cumsum(diag(S).^2)/sum(diag(S).^2);
plot(1:length(energia), energia, '-g', 'LineWidth', 3);
hold on;
xlabel('Valori Singolari')
ylabel('Energia Spiegata')

% Esempio: evidenziare i punti di interesse
punti = [3 6 32 81 127 193]; % Indici dei punti da evidenziare
valori_punti = energia(punti); % Valori corrispondenti

for t = 1 : 6
    % Aggiungi marker sui punti specifici
    plot(punti(t), valori_punti(t), 'bo', 'MarkerFaceColor', 'b'); % Punti con cerchi blu pieni
    text(punti(t), valori_punti(t), sprintf('%.2f%%', valori_punti(t)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

hold off;
%% proietto la matrice nello spazio ridotto
AIris_new=[];
for i=1: size(AIris_matrix, 2)
    AIris_new = [AIris_new (U(:,1:k)' * AIris_matrix(:,i))];
end

% calcolo la correllazione tra la matrice e se stessa
corr_matrix = corr(AIris_new);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;

%% Prendo un immagine dal set di test per confronto con singolo campione
%{
test_path = "path";

AIris_test = double(imread(test_path));

AIris_test = AIris_test(:)-mean_AIris;

% considero vettori colonna
AIris_test_projected = U(:,1:k)' * AIris_test;

% Confronto tramite norma euclidea con tutte le colonne della matrice
distances = [];

for i=1 : size(AIris_matrix, 2)
    stored_AIris = U(:,1:k)' * AIris_matrix(:,i);

    distances = [distances norm(AIris_test_projected - stored_AIris)];
    %distances = [distances mean((AIris_test_projected - stored_AIris).^2)];
    fprintf("Elaboro "+i+"\n")
end

percentage_distances = (1 - distances / max(distances)) * 100;
[value, indices] = max(percentage_distances);

% Calcolo l'indice della persona, considerando che ogni persona ha 5 immagini
personIndex = uint8(indices/5);

fprintf("l'Iride più simile a quello di test è %d al %d%%\n", personIndex, uint8(value))

plot(percentage_distances)
%}

%% calcolo la correlazione con persone mai inserite nel dataset

AIris_test_matrix = [];
for i=46:50
    test_path = "path";

    AIris_test = double(imread(test_path));
    AIris_test = AIris_test(:) - mean_AIris;
    AIris_test = U(:,1:k)' * AIris_test;
    
    AIris_test_matrix = [AIris_test_matrix AIris_test];
    
end

corr_matrix = corr(AIris_new,AIris_test_matrix);
figure;
imagesc(corr_matrix);
colorbar;
title('Matrice di correlazione degli iridi');
colormap jet;
