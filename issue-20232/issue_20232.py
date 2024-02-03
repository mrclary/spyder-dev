# Modul
import tkinter as tk        # Modul import

#Fencter
fenster = tk.Tk()            # Methode Fenstererstellung
fenster.title('Hallo Welt')  # Fenster titel
fenster.geometry('300x100')  # Fensterdimension

# Schaltfläche
schalter = tk.Button(fenster, text='Fenster schließen', command=fenster.destroy)

schalter.pack()

# Bild

bild = tk.PhotoImage(file='208962796-dc607338-94a5-47e6-9676-7b1a0dc4b81e.png')

#Rahmen
rahmen = tk.Canvas(fenster)  # Methode Canvas
rahmen.pack()                # Dimensionierung
rahmen.create_rectangle(5, 5, 162, 60)
rahmen.create_image(5, 5, image=bild, anchor='nw')

# Schleife
fenster.mainloop() # Ereignisschleife
