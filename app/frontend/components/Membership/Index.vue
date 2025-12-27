<template>
    <h1 style="text-align:center; color:green">Afilieri(Club/Sportiv)</h1>
    <input type="text" v-model="searchData" placeholder="Cautare" @input="onSearch" class="form-control" />
    <hr>
    <div class="filter-item">
        <label for="club" class="label-filter">Club</label>
        <select class="custom-select" @change="filter('club_id', $event.target.value)">
            <option value="all">Toate</option>
            <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name}} </option>
        </select>
    </div>
     <div class="filter-item">
        <label for="runner" class="label-filter">Sportiv</label>
        <select class="custom-select" @change="filter('runner_id', $event.target.value)">
            <option value="all">Toate</option>
            <option v-for="runner in filterData.runners" :key="runner.id" :value="runner.id">{{ runner.full_name}} </option>
        </select>
    </div>
    <div class="filter-item">
        <label class="label-filter">Numar Rezultate</label>
        <div class="range-wrapper">
            <input type="runner" min="0" class="custom-input" placeholder="De la" @input="filter('results_count[from]', $event.target.value)" />
            <span class="range-separator">-</span>
             <input type="runner" min="0" class="custom-input" placeholder="Până la" @input="filter('results_count[to]', $event.target.value)" />
        </div>
    </div>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('club_name')">Club</th>
                <th @click="orderTable('full_name')">Sportiv</th>
                <th @click="orderTable('results_count')">Rezultate</th>
                <th colspan="3">Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`memberships/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`runners/${element.runner_id}`">{{element.full_name}}</a></td>
                <td><a :href="`results?membership_id=${element.id}`">{{element.results_count}}</a></td>
                <td><a class="btn btn-sm btn-warning" :href="`memberships/${element.id}`"> Arată </a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const data = ref([])
const searchData = ref("")
const filterData = ref({})

const filters = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "results_count[from]": 0,
    "results_count[to]": 9999
})

onMounted(async () => {
    getFiltersData();

    const params = new URLSearchParams(window.location.search);
    for (const key of params.keys()) {
        filters.value[key] = params.get(key)
    }

    getData()
})

async function getFiltersData() {
    const res = await axios.get('memberships/filters.json')
    filterData.value = res.data
}

async function getData() {
    const params = new URLSearchParams(filters.value).toString();

    const res = await axios.get(`/memberships.json?${params}`)
    data.value = res.data
    const newUrl = `${window.location.pathname}?${params}`
    window.history.replaceState({}, '', newUrl)
}

function onSearch() {
    filters.value["search"] = searchData.value
    getData()
}

function orderTable(sortKey) {
    filters.value["sorting[direction]"] = sortingDirection(sortKey)
    filters.value["sorting[sort_by]"] = sortKey
    getData()
}

function sortingDirection(sortKey) {
    if (filters.value["sorting[sort_by]"] != sortKey || filters.value["sorting[direction"] == "desc") {
        return "asc"
    } else {
        return "desc"
    }
}

function filter(key, value) {
    filters.value[key] = value
    getData();
}
</script>
