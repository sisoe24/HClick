import tkinter as tk
from tkinter import ttk

window = tk.Tk()
window.title("Demo")
window.geometry('200x100')

lbl = ttk.Label(window, text="Text")
lbl.grid(column=0, row=0)


def clicked():
    text = lbl.cget('text')

    if 'Button' in text:
        text += '!'
    else:
        text = 'Button was clicked '

    lbl.configure(text=text)


btn = ttk.Button(window, text="Click Me", command=clicked)
btn.grid(column=0, row=1, sticky=tk.W)

window.mainloop()
