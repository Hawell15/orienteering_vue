<template>
    <h1 style="text-align:center; color:green">Categorii</h1>
    <input type="text" v-model="searchData" placeholder="Cautare" @input="onSearch" class="form-control" />
    <hr>
    <div class="filter-item">
        <label :for="age" class="label-filter">Seniori/Juniori</label>
        <select :id="age" class="custom-select" @change="filter('age', $event.target.value)">
            <option value="all" selected="selected">Toate</option>
            <option value="senior">Seniori</option>
            <option value="junior">Juniori</option>
        </select>
    </div>
    <div class="filter-item">
        <label class="label-filter">Puncte</label>
        <div class="range-wrapper">
            <input type="number" min="0" max="300" class="custom-input" placeholder="De la" @input="filter('points[from]', $event.target.value)" />
            <span class="range-separator">—</span>
            <input type="number" min="0" max="300" class="custom-input" placeholder="Până la" @input="filter('points[to]', $event.target.value)" />
        </div>
    </div>
    <div class="filter-item">
        <label class="label-filter">Validitate(ani)</label>
        <div class="range-wrapper">
            <input type="number" min="2" max="4" class="custom-input" placeholder="De la" @input="filter('validaty_period[from]', $event.target.value)" />
            <span class="range-separator">—</span>
            <input type="number" min="2" max="4" class="custom-input" placeholder="Până la" @input="filter('validaty_period[to]', $event.target.value)" />
        </div>
    </div>
    <div class="filter-item">
        <label class="label-filter">Numar Sportivi</label>
        <div class="range-wrapper">
            <input type="number" min="0" class="custom-input" placeholder="De la" @input="filter('runners_count[from]', $event.target.value)" />
            <span class="range-separator">—</span>
            <input type="number" min="0" class="custom-input" placeholder="Până la" @input="filter('runners_count[to]', $event.target.value)" />
        </div>
    </div>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('category_name')">Nume</th>
                <th @click="orderTable('full_name')">Nume Complet</th>
                <th @click="orderTable('points')">Puncte</th>
                <th @click="orderTable('validaty_period')">Validitate(Ani)</th>
                <th @click="orderTable('runners_count')">Numar Sportivi</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`categories/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.category_name }}</a></td>
                <td><a :href="`categories/${element.id}`">{{ element.full_name }}</a></td>
                <td>{{ element.points }}</td>
                <td>{{ element.validaty_period }}</td>
                <td>
                    <a :href="`/runners?category_id=${element.id}`">
                        {{ element.runners_count }}
                    </a>
                </td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`categories/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editElement(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const data = ref([])
const searchData = ref("")

const filters = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

async function getData() {
    const params = new URLSearchParams(filters.value).toString();

    const res = await axios.get(`/categories.json?${params}`)
    data.value = res.data
    const newUrl = `${window.location.pathname}?${params}`
    window.history.replaceState({}, '', newUrl)
}

onMounted(async () => {
    const params = new URLSearchParams(window.location.search)

    if (params.has('search')) {
        searchData.value = params.get('search')
        filters.value.search = params.get('search')
    }

    if (params.has('sorting[sort_by]')) {
        filters.value["sorting[sort_by]"] = params.get('sorting[sort_by]')
    }

    if (params.has('sorting[direction]')) {
        filters.value["sorting[direction]"] = params.get('sorting[direction]')
    }

    getData()
})

function orderTable(sortKey) {
    filters.value["sorting[direction]"] = sortingDirection(sortKey)
    filters.value["sorting[sort_by]"] = sortKey
    getData()
}

function sortingDirection(sortKey) {
    if (filters.value["sorting[sort_by]"] != sortKey || filters.value["sorting[direction]"] == "desc") {
        return "asc"
    } else {
        return "desc"
    }
}

function onSearch() {
    filters.value["search"] = searchData.value
    getData()
}

function filter(key, value) {
    filters.value[key] = value
    getData()
}
</script>
<style scoped>
.label-filter {
    width: 150px;
    display: inline-block;
    text-align: left;
    margin-bottom: 5px;
}

.custom-select,
.custom-input {
    word-wrap: normal;
    width: 140px;
    border-radius: 0.375rem;
    text-align: center;
    background-color: lightblue;
    border: 1px solid #ced4da;
}

.range-wrapper {
    display: inline-flex;
    align-items: center;
    gap: 8px;
}

.range-separator {
    font-weight: 600;
}
</style>
