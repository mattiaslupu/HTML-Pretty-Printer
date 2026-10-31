# HTML Pretty Printer (Bash & AWK)

Un utilitar în linie de comandă rapid și fără dependențe externe pentru formatarea și indentarea fișierelor HTML. Scris în **Bash** (pentru logica de indentare) și **AWK** (pentru tokenizare lexicală sigură).

## Caracteristici principale

Spre deosebire de scripturile simple bazate pe `sed` care sparg fișierul la fiecare caracter `<` sau `>`, acest utilitar tratează corect cazurile complexe (edge cases) din fișierele HTML reale:

* **Protecție pentru `<script>` și `<style>`:** Codul JavaScript și CSS (ex: `if (a < b && c > d)`) nu este spart în tag-uri false.
* **Conservarea blocurilor `<pre>` și `<textarea>`:** Spațiile albe și liniile noi din interiorul acestor blocuri rămân intacte.
* **Atribute cu caractere speciale:** Simbolurile `<` și `>` aflate în interiorul ghilimelelor (ex: `data-info="a > b"`) sunt ignorate la spargerea tag-urilor.
* **Tag-uri pe mai multe linii (Multiline tags):** Unește automat tag-urile ale căror atribute se întind pe mai multe rânduri.
* **Suport complet HTML5 Void Tags:** Recunoaște elementele fără tag de închidere (`<img>`, `<br>`, `<input>`, `<meta>`, `<link>` etc.) și nu crește eronat nivelul de indentare.
* **Comentarii și declarații speciale:** Gestionează corect comentariile multiline (`<!-- ... -->`), `<!DOCTYPE html>` și instrucțiunile de procesare (`<?xml ... ?>`, `<?php ... ?>`).
* **Performanță ridicată:** Prelucrarea arborelui și a string-urilor se face 100% nativ în Bash (Parameter Expansion), fără a crea subprocese în interiorul buclei.

## Cerințe de sistem

Nu necesită instalarea niciunei biblioteci terțe (precum Node.js, Python sau `tidy`):
* **Bash** 4.0+
* **AWK** (standard pe orice distribuție Linux / macOS / WSL)

## Instalare și Utilizare

1. **Clonează acest repository:**
   ```bash
   git clone [https://github.com/utilizatorul-tau/html-pretty-printer.git](https://github.com/utilizatorul-tau/html-pretty-printer.git)
   cd html-pretty-printer
   ```

2. **Oferă permisiuni de execuție scriptului:**
   ```bash
   chmod +x html_pretty.sh
   ```

3. **Rulează scriptul pe un fișier HTML:**
   ```bash
   # Afișare direct în terminal
   ./html_pretty.sh index.html

   # Salvare într-un fișier nou
   ./html_pretty.sh index.html > index_formatat.html
   ```

## Exemplu

**Input (`test.html`):**
```html
<!DOCTYPE html><html><head><title> Pagina Test </title></head><body><!-- Comentariu --><div 
class="card" data-expr="1 > 0"><img src="logo.png"><p>Salut   lume!</p><script>if (x < 10 && y > 5) { console.log("OK"); }</script></div></body></html>
```

**Output:**
```html
<!DOCTYPE html>
<html>
  <head>
    <title>
      Pagina Test
    </title>
  </head>
  <body>
    <!-- Comentariu -->
    <div class="card" data-expr="1 > 0">
      <img src="logo.png">
      <p>
        Salut lume!
      </p>
      <script>
        if (x < 10 && y > 5) { console.log("OK"); }
      </script>
    </div>
  </body>
</html>
```

## Cum funcționează (Arhitectură)

1. **Etapa 1 — Analiza lexicală (AWK):** Parcurge fișierul caracter cu caracter / linie cu linie, ține evidența stărilor (în interiorul ghilimelelor, comentariilor sau blocurilor raw) și emite un flux standardizat cu prefixe (`TOKEN:`, `TEXT:`, `RAW:`, `PRE:`, `COMMENT:`).
2. **Etapa 2 — Calculul indentării (Bash):** Citește fluxul generat de AWK, ajustează contorul de nivel (`nivel`) pe baza tipului de tag (deschidere, închidere, self-closing sau void tag) și afișează codul formatat folosind `printf`.
