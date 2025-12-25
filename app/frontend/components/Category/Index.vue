<template>
    <h1 style="text-align:center; color:green">Categorii</h1>

    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th v-for="(detail, index) in details" :key="detail.key">{{ detail.header }}</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
             <tr v-for="element in data" :key="element.id">
                <td v-for="(field, index) in details" :key="field.key"> {{ element[field.key] }} </td>
                <td><a class="btn btn-sm btn-warning" :href="`categories/${element.id}`">Arată</a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

onMounted(async () => {
    const res = await axios.get('/categories.json')
    data.value = res.data
})

const data = ref([])

const details = ref([{
        header: "Nume",
        key: "category_name",
        type: "text",
        link: "categories"
    },
    {
        header: "Nume Complet",
        key: "full_name",
        type: "text",
        link: "categories"
    },
    {
        header: "Puncte",
        key: "points",
        type: "number"
    },
    {
        header: "Validitate(Ani)",
        key: "validaty_period",
        type: "number"
    },
    {
        header: "Numar Sportivi",
        key: "runners_count",
        type: "number",
        runners_link: "category",
    }
])
</script>
